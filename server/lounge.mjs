import { randomBytes, createHash, randomUUID } from 'node:crypto';

const prices = Object.freeze({g1:250,g2:500,g3:1500,g4:3000,g5:5000,g6:10000,g7:850,g8:1200,g9:2400,g10:4200,g11:8000});
export function loungeService(db, catalog, allowed, readBody, json) {
  const giftPrices=new Map(Object.entries({...prices,...catalog}));
  db.exec('CREATE TABLE IF NOT EXISTS lounge_guests (token TEXT PRIMARY KEY, public_id TEXT UNIQUE NOT NULL, balance INTEGER NOT NULL CHECK(balance>=0));'+
    'CREATE TABLE IF NOT EXISTS lounge_events (seq INTEGER PRIMARY KEY, room TEXT NOT NULL, actor TEXT NOT NULL, nonce TEXT NOT NULL, kind TEXT NOT NULL, payload TEXT NOT NULL, created INTEGER NOT NULL, UNIQUE(actor,nonce));'+
    'CREATE INDEX IF NOT EXISTS lounge_room_seq ON lounge_events(room,seq);'+
    'CREATE TABLE IF NOT EXISTS lounge_claps (room TEXT, gift TEXT, actor TEXT, PRIMARY KEY(room,gift,actor));');
  db.exec('CREATE TABLE IF NOT EXISTS lounge_media (id TEXT PRIMARY KEY, actor TEXT NOT NULL, room TEXT NOT NULL, mime TEXT NOT NULL, data BLOB NOT NULL)');
  const sessions=new Map(), validId=/^[a-zA-Z0-9-]{8,64}$/, emojis=new Set(['❤️','👏','😂','🎉','🔥','🌹']);
  const lookup=db.prepare('SELECT * FROM lounge_guests WHERE token=?');
  const eventByNonce=db.prepare('SELECT * FROM lounge_events WHERE actor=? AND nonce=?');
  const scan=db.prepare('SELECT * FROM lounge_events WHERE room=? AND seq>? ORDER BY seq LIMIT 100');
  const history=db.prepare('SELECT * FROM (SELECT * FROM lounge_events WHERE room=? ORDER BY seq DESC LIMIT 80) ORDER BY seq');
  const add=db.prepare('INSERT INTO lounge_events(room,actor,nonce,kind,payload,created) VALUES (?,?,?,?,?,?)');
  const version=db.prepare("SELECT COALESCE(max(seq),0) AS rev FROM lounge_events WHERE actor=? AND kind='gift'");
  const clean=(s,max)=>typeof s==='string'?s.trim().slice(0,max):'';
  const fail=(status,message)=>{throw Object.assign(new Error(message),{status});};
  const publicEvent=e=>({seq:e.seq,id:e.nonce,actor:e.actor,kind:e.kind,at:e.created,...JSON.parse(e.payload)});
  function session(req,res,create) {
    const cookie=(req.headers.cookie||'').split(/;\s*/).find(x=>x.startsWith('halaa_lounge='))?.slice(13);
    const digest=s=>createHash('sha256').update(s).digest('hex');
    if(cookie&&/^[0-9a-f]{64}$/.test(cookie)){
      const found=lookup.get(digest(cookie));if(found)return found;
    }
    if(!create)fail(401,'أعد فتح الغرفة لاستعادة الجلسة');
    const token=randomBytes(32).toString('hex'),key=digest(token);
    db.prepare('INSERT INTO lounge_guests VALUES(?,?,?)').run(key,randomUUID(),25400);
    const secure=req.socket.encrypted||req.headers['x-forwarded-proto']==='https';
    res.setHeader('Set-Cookie','halaa_lounge='+token+'; HttpOnly; SameSite=Strict; Path=/; Max-Age=2592000'+(secure?'; Secure':''));
    return lookup.get(key);
  }
  function presence(room,actor,name) {
    const now=Date.now();for(const [key,p] of sessions)if(now-p.at>45000)sessions.delete(key);
    const key=room+'/'+actor,entry=sessions.get(key)||{actor,name:'عضو',at:now};
    if(name)entry.name=name;entry.at=now;sessions.set(key,entry);
    return Array.from(sessions.entries()).filter(([k])=>k.startsWith(room+'/')).slice(-80).map(([,p])=>({id:p.actor,name:p.name}));
  }
  return async function serve(req,res,url){
    if(!url.pathname.startsWith('/api/lounge/'))return false;
    const path=url.pathname.slice(12);
    if(req.method==='GET'&&path.startsWith('file/')){
      session(req,res,false);
      const row=db.prepare('SELECT mime,data,room FROM lounge_media WHERE id=?').get(path.slice(5));
      if(!row||!allowed(row.room))fail(404,'الملف غير موجود');
      res.writeHead(200,{'Content-Type':row.mime,'Content-Length':row.data.byteLength,'X-Content-Type-Options':'nosniff','Cache-Control':'private, max-age=300','Content-Security-Policy':"default-src 'none'"});res.end(row.data);return true;
    }
    if(req.method==='POST'&&path==='media'){
      const who=session(req,res,false).public_id,room=url.searchParams.get('room'),id=url.searchParams.get('id'),mime=req.headers['content-type'];
      if(req.headers['x-halaa-room']!=='1'||!allowed(room)||!validId.test(id||'')||!sessions.has(room+'/'+who))fail(400,'افتح الغرفة قبل إرسال الملف');
      const type=mime?.startsWith('video/')?'video':'image',max=(type==='video'?6:2)*1048576;
      if(!['image/png','image/jpeg','image/webp','video/mp4','video/webm'].includes(mime))fail(415,'صيغة ملف غير مدعومة');
      if(Number(req.headers['content-length'])>max)fail(413,'حجم الملف كبير');
      const before=db.prepare('SELECT actor,room FROM lounge_media WHERE id=?').get(id);if(before){if(before.actor!==who||before.room!==room)fail(409,'تعارض في الملف');json(res,200,{ok:true});return true;}
      let size=0;const chunks=[];for await(const chunk of req){size+=chunk.length;if(size>max)fail(413,'حجم الملف كبير');chunks.push(chunk);}
      const bytes=Buffer.concat(chunks),head=bytes.toString('hex',0,12);
      const matches={'image/png':head.startsWith('89504e470d0a1a0a'),'image/jpeg':head.startsWith('ffd8ff'),'image/webp':head.startsWith('52494646')&&bytes.toString('ascii',8,12)==='WEBP','video/mp4':bytes.toString('ascii',4,8)==='ftyp','video/webm':head.startsWith('1a45dfa3')};
      if(!matches[mime])fail(415,'تعذر قراءة صيغة الملف');
      const total=db.prepare('SELECT COALESCE(sum(length(data)),0) AS n FROM lounge_media WHERE actor=?').get(who).n;
      if(total+size>40*1048576)fail(413,'اكتملت مساحة وسائط هذا الحساب التجريبي');
      db.exec('BEGIN IMMEDIATE');try{db.prepare('INSERT INTO lounge_media VALUES(?,?,?,?,?)').run(id,who,room,mime,bytes);
        add.run(room,who,id,'media',JSON.stringify({sender:sessions.get(room+'/'+who)?.name||'عضو',type}),Date.now());db.exec('COMMIT');
      }catch(e){db.exec('ROLLBACK');throw e;}json(res,201,{ok:true});return true;
    }
    if(req.method!=='POST'||!['join','poll','send'].includes(path))fail(404,'الطلب غير متاح');
    if(req.headers['x-halaa-room']!=='1'||!req.headers['content-type']?.startsWith('application/json'))fail(400,'طلب الغرفة غير صالح');
    const data=await readBody(req);
    if(!data||!allowed(data.room))fail(404,'هذه الغرفة غير متصلة بالخادم');
    const me=session(req,res,path==='join'),room=data.room,who=me.public_id;
    const name=clean(data.name,35),people=presence(room,who,path==='join'?name:null);
    const sender=sessions.get(room+'/'+who).name;
    if(path==='join'||path==='poll'){
      const rows=path==='join'?history.all(room):scan.all(room,Number.isSafeInteger(data.after)&&data.after>=0?data.after:0);
      json(res,200,{me:who,balance:me.balance,walletVersion:version.get(who).rev,people,events:rows.map(publicEvent)});return true;
    }
    const {id,kind}=data;
    if(!validId.test(String(id))||typeof id!=='string'||!['chat','reaction','gift','clap'].includes(kind))fail(400,'الحدث غير صالح');
    const previous=eventByNonce.get(who,id);
    if(previous){
      if(previous.room!==room||previous.kind!==kind)fail(409,'تعارض مع عملية سابقة');
      json(res,200,{event:publicEvent(previous),balance:me.balance,walletVersion:version.get(who).rev});return true;
    }
    const recent=db.prepare('SELECT count(*) AS n FROM lounge_events WHERE actor=? AND created>?').get(who,Date.now()-5000).n;
    if(recent>=12)fail(429,'تمهّل لحظة قبل الإرسال');
    const payload={sender};let cost=0;
    if(kind==='chat'){
      if(typeof data.text!=='string'||!data.text.trim()||data.text.length>350)fail(400,'النص بين حرف و٣٥٠ حرفاً');
      payload.text=data.text.trim();if(typeof data.reply==='string')payload.reply=clean(data.reply,110);
    }
    if(kind==='reaction'){if(!emojis.has(data.emoji))fail(400,'تفاعل غير صالح');payload.emoji=data.emoji;}
    if(kind==='gift'){
      cost=giftPrices.get(data.giftId);if(!cost)fail(400,'هدية غير متاحة');
      payload.giftId=data.giftId;
      if(data.to){const person=people.find(p=>p.id===data.to);if(!person)fail(409,'غادر المستلم الغرفة');payload.target=person.name;payload.to=person.id;}
      else payload.target='الغرفة';
    }
    if(kind==='clap'){
      if(typeof data.gift!=='string'||!validId.test(data.gift)||!db.prepare("SELECT seq FROM lounge_events WHERE room=? AND nonce=? AND kind='gift' AND created>?").get(room,data.gift,Date.now()-120000))fail(400,'انتهى عرض هذه الهدية');
      payload.gift=data.gift;
    }
    db.exec('BEGIN IMMEDIATE');
    try{
      if(cost&&!db.prepare('UPDATE lounge_guests SET balance=balance-? WHERE token=? AND balance>=?').run(cost,me.token,cost).changes)fail(409,'رصيد هدايا الغرفة غير كافٍ');
      if(kind==='clap'&&!db.prepare('INSERT OR IGNORE INTO lounge_claps VALUES(?,?,?)').run(room,data.gift,who).changes)fail(409,'سبق أن صفقت لهذه الهدية');
      add.run(room,who,id,kind,JSON.stringify(payload),Date.now());
      db.exec('COMMIT');
    }catch(e){db.exec('ROLLBACK');throw e;}
    json(res,200,{event:publicEvent(eventByNonce.get(who,id)),balance:lookup.get(me.token).balance,walletVersion:version.get(who).rev});return true;
  };
}
