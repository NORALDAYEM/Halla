import test from 'node:test';
import assert from 'node:assert/strict';
import {createServer} from 'node:http';
import {spawn} from 'node:child_process';
import {once} from 'node:events';

test('room and advert permissions are enforced by the server', async t=>{
  const auth=createServer((req,res)=>{
    const id=req.headers.authorization?.slice(7);
    if(!['host','guest','admin'].includes(id)){res.writeHead(401);return res.end();}
    res.setHeader('content-type','application/json');
    res.end(JSON.stringify({id,email_confirmed_at:'today',app_metadata:{halaa_admin:id==='admin'}}));
  }).listen(0,'127.0.0.1');
  await once(auth,'listening');t.after(()=>auth.close());
  const port=31872, base='http://127.0.0.1:'+port;
  const proc=spawn(process.execPath,['app.mjs'],{env:{...process.env,PORT:String(port),HALAA_DB:':memory:',SUPABASE_URL:'http://127.0.0.1:'+auth.address().port,SUPABASE_PUBLISHABLE_KEY:'test',LIVEKIT_URL:'wss://localhost',LIVEKIT_API_KEY:'test',LIVEKIT_API_SECRET:'test-secret-used-only-for-unit-tests'}});
  t.after(()=>proc.kill());
  let logs='';proc.stderr.on('data',c=>logs+=c);
  for(let i=0;i<60;i++){if(proc.exitCode!==null)assert.fail(logs);try{await fetch(base+'/api/config');break;}catch{await new Promise(r=>setTimeout(r,100));}}
  const post=(path,id,data)=>fetch(base+'/api/'+path,{method:'POST',headers:{authorization:'Bearer '+id,'content-type':'application/json'},body:JSON.stringify(data)});
  assert.equal((await post('voice','bad',{room:'r1'})).status,401);
  const created=await post('rooms','host',{title:'غرفة اختبار',category:'شعر'});assert.equal(created.status,201);
  const {id:room}=await created.json();
  for(const [id,role,canPublish] of [['host','owner',true],['guest','listener',false]]){
    const result=await post('voice',id,{room});assert.equal(result.status,200);
    const payload=await result.json();assert.equal(payload.role,role);
    const jwt=JSON.parse(Buffer.from(payload.token.split('.')[1],'base64url'));assert.equal(jwt.video.canPublish,canPublish);assert.equal(jwt.video.room,'halaa-'+room);
  }
  assert.equal((await post('moderate','guest',{room,target:'host',action:'remove'})).status,403);
  assert.equal((await post('ad','guest',{})).status,403);
  const ad={enabled:true,title:'هلاا',badge:'جديد',subtitle:'غرف',cta:'دخول',imageIndex:0,motion:'fade',effect:'gold',start:20,end:10};
  assert.equal((await post('ad','admin',ad)).status,400);ad.end=30;
  assert.equal((await post('ad','admin',ad)).status,200);
  const config=await (await fetch(base+'/api/config')).json();assert.deepEqual(config.ad,ad);assert.equal(config.rooms[0].id,room);
});
