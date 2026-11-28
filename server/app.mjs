import crypto from 'node:crypto';
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { DatabaseSync } from 'node:sqlite';
import { AccessToken, RoomServiceClient, TrackSource } from 'livekit-server-sdk';
import { createCentralAdminSystem } from './src/central-admin-router.mjs';
const env = process.env;
const zegoAppId = Number(env.ZEGO_APP_ID || 828861219);
const zegoServerSecret = (env.ZEGO_SERVER_SECRET || '').trim();
const zegoReady = Boolean(Number.isSafeInteger(zegoAppId) && zegoAppId > 0 && Buffer.byteLength(zegoServerSecret) === 32);

export function generateZegoToken04(appId, userId, secret, effectiveTimeInSeconds = 3600, payload = '') {
  if (!appId || typeof appId !== 'number') fail(500, 'ZEGO_APP_ID غير صالح');
  if (!userId || typeof userId !== 'string') fail(400, 'معرّف المستخدم غير صالح');
  if (!secret || secret.length !== 32) fail(503, 'يرجى ضبط متغير ZEGO_SERVER_SECRET (32 حرفاً) على الخادم');
  const createTime = Math.floor(Date.now() / 1000);
  const tokenInfo = {
    app_id: appId,
    user_id: userId,
    nonce: crypto.randomInt(2147483647),
    ctime: createTime,
    expire: createTime + effectiveTimeInSeconds,
    payload: payload || ''
  };
  const plainText = JSON.stringify(tokenInfo);
  const iv = crypto.randomBytes(16).toString('hex').slice(0, 16);
  const cipher = crypto.createCipheriv('aes-256-cbc', Buffer.from(secret, 'utf8'), Buffer.from(iv, 'utf8'));
  const encrypted = Buffer.concat([cipher.update(plainText, 'utf8'), cipher.final()]);

  const b1 = Buffer.alloc(8);
  b1.writeBigInt64BE(BigInt(tokenInfo.expire), 0);
  const b2 = Buffer.alloc(2);
  b2.writeUInt16BE(iv.length, 0);
  const b3 = Buffer.from(iv, 'utf8');
  const b4 = Buffer.alloc(2);
  b4.writeUInt16BE(encrypted.length, 0);

  return '04' + Buffer.concat([b1, b2, b3, b4, encrypted]).toString('base64');
}

const db = new DatabaseSync(env.HALAA_DB || 'halaa.sqlite');
db.exec('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
const read = key => JSON.parse(db.prepare('SELECT value FROM settings WHERE key=?').get(key)?.value ?? 'null');
const write = (key, value) => db.prepare('INSERT OR REPLACE INTO settings VALUES (?,?)').run(key, JSON.stringify(value));
const authReady = Boolean(env.SUPABASE_URL && env.SUPABASE_PUBLISHABLE_KEY);
const voiceReady = Boolean(authReady && env.LIVEKIT_URL && env.LIVEKIT_API_KEY && env.LIVEKIT_API_SECRET);
const live = voiceReady && new RoomServiceClient(env.LIVEKIT_URL.replace(/^wss:/,'https:'),env.LIVEKIT_API_KEY,env.LIVEKIT_API_SECRET);
let snapshot, expiresAt=0, pendingPresence;
async function presence(){
  if(!live) return {};
  if(snapshot && Date.now()<expiresAt)return snapshot;
  pendingPresence ||= live.listRooms().then(rooms=>{
    snapshot=Object.fromEntries(rooms.filter(r=>r.name.startsWith('halaa-')).map(r=>[r.name.slice(6),r.numParticipants]));
    expiresAt=Date.now()+10000;return snapshot;
  }).finally(()=>pendingPresence=null);
  return pendingPresence;
}
const roomIds = new Set(JSON.parse(env.HALAA_ROOM_IDS || '["r1","r2","r3","r4","r5","r6"]'));
function fail(status, message) { throw Object.assign(new Error(message), {status}); }
async function identity(req) {
  if (!authReady) fail(503,'خدمة الحسابات غير متصلة');
  const authorization = req.headers.authorization || '';
  if (!authorization.startsWith('Bearer ')) fail(401,'سجّل الدخول أولاً');
  const result = await fetch(new URL('/auth/v1/user',env.SUPABASE_URL), {headers:{authorization,apikey:env.SUPABASE_PUBLISHABLE_KEY},signal:AbortSignal.timeout(8000)});
  if (!result.ok) fail(401,'انتهت جلسة الدخول');
  const user = await result.json();
  if (!user.id || !user.email_confirmed_at) fail(403,'أكّد بريدك أولاً');
  return user;
}
async function guestIdentity(req) {
  if ((req.headers.authorization || '').startsWith('Bearer ')) return identity(req);
  const raw = String(req.headers['x-guest-id'] || '').trim().replace(/[^a-zA-Z0-9_-]/g, '').slice(0, 64);
  const id = raw ? (raw.startsWith('guest_') ? raw : 'guest_' + raw) : 'guest_' + crypto.randomBytes(6).toString('hex');
  return { id, isGuest: true, user_metadata: { nickname: 'Guest' } };
}
async function body(req) {
  const chunks=[]; let bytes=0;
  for await (const c of req) { bytes+=c.length; if(bytes>16384) fail(413,'الطلب كبير'); chunks.push(c); }
  try { return JSON.parse(Buffer.concat(chunks).toString()); } catch { fail(400,'بيانات غير صالحة'); }
}
function roomRole(user,room) {
  if (user.app_metadata?.halaa_admin === true || read('room:'+room)?.owner===user.id) return 'owner';
  const assigned = user.app_metadata?.halaa_rooms?.[room];
  if (assigned==='owner'||assigned==='moderator') return assigned;
  const override=read('role:'+room+':'+user.id);
  if(override==='listener'||override==='owner'||override==='moderator') return override;
  const seats=read('seats:'+room)||{};
  return Object.values(seats).some(s=>s.userID===user.id&&s.expires>Date.now())?'speaker':'listener';
}
function grant(role) {
  return {canSubscribe:true,canPublish:['owner','moderator','speaker'].includes(role),canPublishSources:[TrackSource.MICROPHONE],canPublishData:true};
}
const json=(res,status,data)=>{res.writeHead(status,{'content-type':'application/json; charset=utf-8','cache-control':'no-store'});res.end(JSON.stringify(data));};
export function validAd(a) {
  if (!a || typeof a.enabled!=='boolean' || !['gold','diamond','shimmer','none'].includes(a.effect) || !['zoom','fade','pulse','static'].includes(a.motion)) return false;
  return ['title','subtitle','badge','cta'].every(k=>typeof a[k]==='string'&&a[k].trim().length>0&&a[k].length<=180)
    && Number.isInteger(a.imageIndex) && a.imageIndex>=0 && a.imageIndex<4
    && ['start','end'].every(k=>a[k]===null || Number.isFinite(a[k])) && (a.start===null || a.end===null || a.start<a.end);
}
const validRoom = room => typeof room === 'string' && (roomIds.has(room) || Boolean(read('room:'+room)));
const centralAdmin = createCentralAdminSystem({
  ledgerStorage:{load:()=>read('finance:ledger'),save:value=>write('finance:ledger',value)},
  manageVoiceRoom(data) {
    if(!validRoom(data.room)) fail(404,'الغرفة غير موجودة');
    const target=data.target;
    if(typeof target!=='string'||target.length>128||!target) fail(400,'اختر مستخدماً');
    if(!['speaker','listener','ban','unban'].includes(data.action)) fail(400,'عملية غير مدعومة');
    if(['owner','moderator'].includes(read('role:'+data.room+':'+target)) || read('room:'+data.room)?.owner===target) fail(403,'لا يمكن تعديل رتبة إدارية');
    if(data.action==='ban'||data.action==='unban') write('zego-ban:'+data.room+':'+target,data.action==='ban');
    else write('role:'+data.room+':'+target,data.action);
    return {room:data.room,target,action:data.action};
  },
}); const DEFAULT_ROOM_LEVELS = [{level:1,name:'غرفة مبتدئة',micCount:9,maxVisitors:50,upgradePoints:0},{level:2,name:'غرفة نشطة',micCount:10,maxVisitors:100,upgradePoints:500},{level:3,name:'غرفة مميزة',micCount:12,maxVisitors:200,upgradePoints:2000},{level:4,name:'غرفة ذهبية',micCount:14,maxVisitors:500,upgradePoints:5000},{level:5,name:'غرفة ماسية',micCount:16,maxVisitors:1000,upgradePoints:10000}];
const DEFAULT_ROOM_CONFIG = {micCount:9,roomLevel:1,levels:DEFAULT_ROOM_LEVELS,allowGuestMic:true,allowGuestGifts:true,allowGifts:true,allowChat:true,welcomeMessage:'أهلاً بكم في غرفة هلاا الصوتية',roomTitleArabic:''};
const normalizeRoomConfig = (raw={}) => { const c = {...DEFAULT_ROOM_CONFIG,...(raw&&typeof raw==='object'?raw:{})}; const m = Number(c.micCount), l = Number(c.roomLevel); c.micCount = Number.isInteger(m)?Math.min(16,Math.max(2,m)):9; c.roomLevel = Number.isInteger(l)?Math.min(10,Math.max(1,l)):1; c.levels = Array.isArray(c.levels)&&c.levels.length?c.levels:DEFAULT_ROOM_LEVELS; c.allowGuestMic = Boolean(c.allowGuestMic); c.allowGuestGifts = Boolean(c.allowGuestGifts); c.allowGifts = Boolean(c.allowGifts); c.allowChat = Boolean(c.allowChat); c.welcomeMessage = typeof c.welcomeMessage==='string'&&c.welcomeMessage.trim()?c.welcomeMessage:DEFAULT_ROOM_CONFIG.welcomeMessage; c.roomTitleArabic = typeof c.roomTitleArabic==='string'?c.roomTitleArabic:''; return c; };
if (!read('rooms-config:global')) write('rooms-config:global', DEFAULT_ROOM_CONFIG); const getRoomConfig = (room='') => { const g = read('rooms-config:global') || DEFAULT_ROOM_CONFIG; const r = room ? (read('rooms-config:'+room) || {}) : {}; return normalizeRoomConfig({...g,...r}); };
createServer(async(req,res)=>{
  try {
    if (await centralAdmin.handleRequest(req, res)) return;
    const path=new URL(req.url,'http://localhost').pathname;
    if(req.method==='GET' && ['/health','/healthz'].includes(path)) return json(res,200,{ok:true,service:'halaa-room-service',voice:{provider:'zego',configured:zegoReady},authConfigured:authReady});
    if(path.startsWith('/api/') && req.headers.origin==='https://noraldayem.github.io'){
      res.setHeader('Access-Control-Allow-Origin',req.headers.origin);
      res.setHeader('Vary','Origin');
      if(req.method==='OPTIONS'){
        res.writeHead(204,{'Access-Control-Allow-Methods':'GET, POST, OPTIONS','Access-Control-Allow-Headers':'Content-Type, Authorization, x-guest-id'});
        return res.end();
      }
    }
    if(req.method==='GET' && ['/','/halaa_voice_app.html','/halaa_mobile_screens_showcase.html'].includes(path)){
      const file=path.includes('showcase')?'halaa_mobile_screens_showcase.html':'halaa_voice_app.html';
      const content=await readFile(new URL('../'+file,import.meta.url));
      res.writeHead(200,{'content-type':'text/html; charset=utf-8','referrer-policy':'no-referrer'});return res.end(content);
    } if(req.method==='GET' && path==='/api/rooms/config'){const room=new URL(req.url,'http://localhost').searchParams.get('room')||'';if(room&&!validRoom(room))fail(404,'Room not found');const cfg=getRoomConfig(room);return json(res,200,{ok:true,room:room||'global',...cfg,config:cfg});}
    if(req.method==='POST' && path==='/api/rooms/config'){const data=await body(req);const room=typeof data.room==='string'?data.room:(typeof data.roomId==='string'?data.roomId:'');if(room&&!validRoom(room))fail(404,'Room not found');const patch=(data.config&&typeof data.config==='object')?data.config:data;if(patch.micCount!==undefined){const m=Number(patch.micCount);if(!Number.isInteger(m)||m<2||m>16)fail(400,'micCount must be between 2 and 16');}if(patch.roomLevel!==undefined){const l=Number(patch.roomLevel);if(!Number.isInteger(l)||l<1||l>10)fail(400,'roomLevel must be between 1 and 10');}const key=room?'rooms-config:'+room:'rooms-config:global';const prev=read(key)||(room?{}:DEFAULT_ROOM_CONFIG);const allowed=['micCount','roomLevel','levels','allowGuestMic','allowGuestGifts','allowGifts','allowChat','welcomeMessage','roomTitleArabic'];const next={...prev};for(const k of allowed)if(patch[k]!==undefined)next[k]=patch[k];write(key,room?next:normalizeRoomConfig(next));const cfg=getRoomConfig(room);return json(res,200,{ok:true,room:room||'global',...cfg,config:cfg});}
    if(req.method==='GET' && path==='/api/presence')return json(res,200,await presence());
    if(req.method==='GET' && path==='/api/config') return json(res,200,{authUrl:env.SUPABASE_URL||'',publicKey:env.SUPABASE_PUBLISHABLE_KEY||'',voiceReady:voiceReady||zegoReady,zegoAppId,zegoReady,ad:read('homeAd'),rooms:db.prepare("SELECT value FROM settings WHERE key LIKE 'room:%' ORDER BY rowid DESC LIMIT 200").all().map(row=>{const {id,title,category}=JSON.parse(row.value);return {id,title,category};})});
    if(req.method==='GET' && path==='/api/zego/token') return json(res,405,{error:'Use authenticated POST'});
    if(req.method==='POST' && ['/api/zego-token','/api/zego/token'].includes(path)){
      if(!zegoReady) fail(503,'يرجى ضبط متغير ZEGO_SERVER_SECRET في إعدادات الخادم');
          const user=await guestIdentity(req);
      if(centralAdmin.controlSync.getCurrentConfig().value.features.voiceRooms===false) fail(503,'الغرف متوقفة مؤقتاً للصيانة');
      const data=await body(req);
      const room=data.room ?? (typeof data.roomID==='string' ? data.roomID.replace(/^halaa_/,'') : '');
      if(typeof room!=='string'||!room||(!roomIds.has(room)&&!read('room:'+room))) fail(404,'الغرفة غير موجودة');
      const roomID='halaa_'+room, userID=user.id, role=user.isGuest&&read('role:'+room+':'+userID)!=='listener'?'speaker':roomRole(user,room);
      if(read('zego-ban:'+room+':'+userID)) fail(403,'تم منع الدخول لهذه الغرفة');
     const seats=read('seats:'+room)||{};
      for(const seat of Object.values(seats)) if(seat.userID===userID&&seat.expires>Date.now()) seat.expires=Date.now()+60000;
      write('seats:'+room,seats);
      write('member:'+userID,{id:userID})
      const cfg=getRoomConfig(room);const roomConfig={micCount:cfg.micCount,roomLevel:cfg.roomLevel,levels:cfg.levels,allowGifts:cfg.allowGifts,allowChat:cfg.allowChat,allowGuestMic:cfg.allowGuestMic,welcomeMessage:cfg.welcomeMessage};
      const payload=JSON.stringify({room_id:roomID,privilege:{1:1,2:grant(role).canPublish?1:0},stream_id_list:null});
      const token=generateZegoToken04(zegoAppId,userID,zegoServerSecret,900,payload);
      return json(res,200,{roomConfig,appID:zegoAppId,roomID,userID,role,token,expiresIn:900,userName:String(user.user_metadata?.nickname || user.user_metadata?.display_name || user.email?.split('@')[0] || 'عضو').slice(0,60)});
    }
    if(req.method==='POST' && path==='/api/seat') {
      const user=await guestIdentity(req),data=await body(req);
      if(!validRoom(data.room)) fail(404,'الغرفة غير موجودة');
      if(read('zego-ban:'+data.room+':'+user.id)) fail(403,'الدخول ممنوع');
      if(!['take','release'].includes(data.action)) fail(400,'عملية غير مدعومة');
    if(user.isGuest) write('member:'+user.id,{id:user.id});
      const seats=read('seats:'+data.room)||{};
      for(const [index,seat] of Object.entries(seats)) if(seat.expires<=Date.now()||seat.userID===user.id) delete seats[index];
      if(data.action==='take') {
        if(!Number.isInteger(data.index)||data.index<0||data.index>=getRoomConfig(data.room).micCount/*8 */)fail(400,'المقعد غير صالح');
        if(data.index===0&&roomRole(user,data.room)!=='owner') fail(403,'مقعد المضيف محجوز');
        if(seats[data.index]) fail(409,'المقعد مشغول');
        if(read('role:'+data.room+':'+user.id)==='listener') fail(403,'الميكروفون مقفل من الإدارة');
        seats[data.index]={userID:user.id,expires:Date.now()+60000};
      }
      write('seats:'+data.room,seats);
      return json(res,200,{ok:true});
    }
    if(req.method==='GET' && path==='/api/wallet') {
      const user=await identity(req);
      return json(res,200,{coins:centralAdmin.ledgerService.getBalance(user.id,'COINS'),diamonds:centralAdmin.ledgerService.getBalance(user.id,'DIAMONDS')});
    }
    if(path==='/api/gifts' && (req.method==='POST'||req.method==='GET')) {
      const user=await guestIdentity(req);
      const data=req.method==='POST'?await body(req):Object.fromEntries(new URL(req.url,'http://localhost').searchParams);
      if(!validRoom(data.room)) fail(404,'الغرفة غير موجودة');
      if(read('zego-ban:'+data.room+':'+user.id)) fail(403,'الدخول ممنوع');
    if(user.isGuest) write('member:'+user.id,{id:user.id});
      if(req.method==='GET') {
        const gifts=[...centralAdmin.ledgerService.idempotencyCache.values()].filter(g=>g.roomId===data.room&&g.giftId).slice(-50);
              return json(res,200,{gifts:[...gifts,...(read('guest-gifts:'+data.room)||[])].slice(-50)});
      }
      if(centralAdmin.controlSync.getCurrentConfig().value.features.gifts===false) fail(503,'الهدايا متوقفة مؤقتاً');
      if(typeof data.recipientId!=='string'||!read('member:'+data.recipientId)) fail(404,'المستلم غير موجود');
    if(user.isGuest||String(data.recipientId).startsWith('guest_')){
      const key='guest-gifts:'+data.room,list=read(key)||[],idem=typeof data.idempotencyKey==='string'&&data.idempotencyKey?data.idempotencyKey:null;
      const existing=idem?list.find(g=>g.idempotencyKey===idem):null;
      if(existing) return json(res,200,{ok:true,gift:existing,idempotent:true});
      const gift={id:crypto.randomUUID(),senderId:user.id,recipientId:data.recipientId,giftId:data.giftId,roomId:data.room,idempotencyKey:idem,isGuest:true,createdAt:Date.now()};
      list.push(gift);write(key,list.slice(-100));
      return json(res,200,{ok:true,gift});
    }
      return json(res,200,centralAdmin.ledgerService.sendGift({senderId:user.id,recipientId:data.recipientId,giftId:data.giftId,roomId:data.room,idempotencyKey:data.idempotencyKey}));
    }
    if(req.method!=='POST' || !['/api/ad','/api/voice','/api/moderate','/api/rooms'].includes(path)) return json(res,404,{});
    const user=await identity(req), data=await body(req);
    if(path==='/api/rooms'){
      if(typeof data.title!=='string'||!data.title.trim()||data.title.length>64||!['دردشة','ألعاب','شعر','غناء','قرآن'].includes(data.category)) fail(400,'تحقق من اسم الغرفة وتصنيفها');
      const count=db.prepare("SELECT count(*) AS n FROM settings WHERE key LIKE 'room:%' AND json_extract(value,'$.owner')=?").get(user.id).n;
      if(count>=10) fail(409,'وصلت إلى الحد المسموح من الغرف');
      const id='room-'+crypto.randomUUID();
      write('room:'+id,{id,title:data.title.trim(),category:data.category,owner:user.id});
      return json(res,201,{id});
    }
    if(path==='/api/ad'){
      if(user.app_metadata?.halaa_admin!==true) fail(403,'تعديل الإعلان متاح للإدارة فقط');
      if(!validAd(data)) fail(400,'تحقق من بيانات الإعلان ومواعيده');
      write('homeAd',data);return json(res,200,{ok:true});
    }
    if(!voiceReady) fail(503,'خدمة الصوت غير متصلة');
    if(typeof data.room!=='string'||data.room.length>80||(!roomIds.has(data.room)&&!read('room:'+data.room))) fail(404,'لم تُفعّل هذه الغرفة على الخادم');
    const role=roomRole(user,data.room), room='halaa-'+data.room;
    if(path==='/api/moderate'){
      if(!['owner','moderator'].includes(role)) fail(403,'هذه العملية للمشرفين فقط');
      if(!['mute','remove','speaker','listener'].includes(data.action)||typeof data.target!=='string'||data.target===user.id) fail(400,'اختر مشاركاً آخر');
      const target=await live.getParticipant(room,data.target);
      const rank=JSON.parse(target.metadata||'{}').role;
      if(rank==='owner'||(role==='moderator'&&rank==='moderator')) fail(403,'الصلاحية غير كافية');
      if(data.action==='remove') await live.removeParticipant(room,data.target);
      else if(data.action==='speaker'||data.action==='listener'){
        if(rank==='moderator'||rank==='owner') fail(403,'لا يمكن تغيير رتبة إدارية من المقاعد');
        await live.updateParticipant(room,data.target,{metadata:JSON.stringify({role:data.action}),permission:grant(data.action)});
        write('role:'+data.room+':'+data.target,data.action);
      } else for(const track of target.tracks.filter(t=>t.source===TrackSource.MICROPHONE)) await live.mutePublishedTrack(room,data.target,track.sid,true);
      return json(res,200,{ok:true});
    }
    const token=new AccessToken(env.LIVEKIT_API_KEY,env.LIVEKIT_API_SECRET,{identity:user.id,name:String(user.user_metadata?.display_name||'عضو').slice(0,60),ttl:'5m',metadata:JSON.stringify({role})});
    token.addGrant({roomJoin:true,room,...grant(role),canUpdateOwnMetadata:false});
    return json(res,200,{url:env.LIVEKIT_URL,token:await token.toJwt(),role});
  } catch(e){return json(res,e.status||e.statusCode||503,{error:(e.status||e.statusCode)?e.message:'تعذر إتمام الاتصال بالخدمة'});}
}).listen(Number(env.PORT||3000),'0.0.0.0');
