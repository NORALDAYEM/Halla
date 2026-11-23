'use strict';
const $ = selector => document.querySelector(selector);
const url = new URL(location.href);
const view = url.searchParams.get('view') || 'home';
const go = view => location.assign('member.html?view=' + encodeURIComponent(view));
const authModes = {login:'تسجيل الدخول',signup:'إنشاء حساب',reset:'استعادة الحساب',username:'الدخول باسم المستخدم',phone:'الدخول بالهاتف',recover:'تعيين كلمة مرور جديدة'};
let client, user, voice, generation = 0;
const sdk = import('https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.49.4/+esm').then(({createClient}) => {
  client=createClient('https://uwjrboviicypyhregpoo.supabase.co','sb_publishable_QbUKNVMYDRK63NjB26tCtw_jzOaEXdR',{auth:{flowType:'pkce'}});
  client.auth.onAuthStateChange((event,session)=>{
    user=session?.user;
    if(event==='SIGNED_OUT'){endVoice();location.replace('studio/');return;}
    $('#identity').textContent=user?.user_metadata?.nickname || (user?'عضو هلاا':'ضيف هلاا');
    $('#accountAction').textContent=user?'خروج':'دخول';
    if(user && !['reset','recover'].includes(view) && view in authModes) location.replace('member.html');
    if(user?.user_metadata?.nickname && user.email) localStorage.setItem('halla.alias.'+user.user_metadata.nickname.trim().toLowerCase(),user.email);
  });
  return client;
}).catch(()=>null);
function notice(title,message){
  $('#notice h2').textContent=title;$('#notice p').textContent=message;$('#notice').showModal();
}
$('#dismiss').onclick=()=>$('#notice').close();
$('#accountAction').onclick=async()=>{
  if(!user){go('login');return;}
  const {error}=await client.auth.signOut({scope:'local'});
  if(error)notice('تعذّر الخروج','أعد المحاولة.');
};
$('#profile').onclick=()=>user?notice('حسابي',user.user_metadata?.nickname || 'عضو هلاا'):go('login');
function authScreen(mode){
  $('#auth').hidden=false;$('#formTitle').textContent=authModes[mode];
  const form=$('form');
  for(const [id,visible] of [['nameLabel',['username','signup'].includes(mode)],['passLabel',!['reset','phone'].includes(mode)],['emailLabel',['signup','login','reset'].includes(mode)]]){
    $('#'+id).hidden=!visible;$('#'+id+' input').required=visible;
  }
  form.password.autocomplete=['signup','recover'].includes(mode)?'new-password':'current-password';
  form.password.minLength=['signup','recover'].includes(mode)?10:1;
  $('#alt').textContent=mode==='login'?'إنشاء حساب بالبريد الإلكتروني':'الدخول بالبريد الإلكتروني';
  $('#alt').onclick=()=>go(mode==='login'?'signup':'login');
  if(mode==='phone'){form.hidden=true;$('#status').textContent='الدخول بالهاتف ينتظر تفعيل خدمة الرسائل النصية.';return;}
  if(mode==='username')$('#status').textContent='استخدم اسم حساب سبق تسجيل دخوله بالبريد على هذا الجهاز.';
  form.onsubmit=async event=>{
    event.preventDefault();$('#submit').disabled=true;
    try{
      if(!await sdk)throw Error();
      const mail=form.email.value.trim(),password=form.password.value,nickname=form.nickname.value.trim();
      const redirect=new URL('member.html',location.href);
      let result;
      if(mode==='reset'){redirect.search='?view=recover';result=await client.auth.resetPasswordForEmail(mail,{redirectTo:redirect.href});}
      else if(mode==='signup')result=await client.auth.signUp({email:mail,password,options:{data:{nickname},emailRedirectTo:redirect.href}});
      else if(mode==='recover')result=await client.auth.updateUser({password});
      else result=await client.auth.signInWithPassword({email:mode==='username'?localStorage.getItem('halla.alias.'+nickname.toLowerCase())||'':mail,password});
      if(result.error)throw result.error;
      if(mode==='signup'||mode==='reset')$('#status').textContent='راجع بريدك الإلكتروني لإكمال الطلب.';
      else location.replace('member.html');
    }catch{$('#status').textContent='تعذّر إكمال الطلب. تحقق من البيانات والاتصال ثم حاول مجددًا.';}
    finally{$('#submit').disabled=false;}
  };
}
const games=[['LUDO','🎲','#03c882','#009d74'],['CARROM','◉','#ff9646','#e4522f'],['BALOOT','🂡','#fbc65f','#c5892e'],['UMO','🃏','#00cfe0','#009dbf']];
for(const [name,icon,a,b] of games){
  const btn=document.createElement('button');btn.className='game '+name.toLowerCase();btn.style.setProperty('--a',a);btn.style.setProperty('--b',b);
  const mark=document.createElement('span');mark.textContent=icon;mark.ariaHidden='true';btn.append(mark,name);
  btn.onclick=()=>notice('قريبًا', 'لعبة '+name+' ستتوفر قريبًا في هلاا.');$('.gamegrid').append(btn);
}
const rooms=[{"id": "r1", "title": "مجلس السوالف والقصيد 🇸🇦", "category": "شعر", "cover": "assets/54e916da3ef118b4b2be0f374b01afba2f3338b325b76807d36341691e7d6b3d.jpg"}, {"id": "r2", "title": "تحدي اللودو والبلياردو 🎮", "category": "ألعاب", "cover": "assets/9a85cfcb0bfae832b74addffc0d5b1b16cce4fbfc1340471faf1162281c5a908.jpg"}, {"id": "r3", "title": "جلسة طرب وعود هادئة 🎶", "category": "غناء", "cover": "assets/0bbde3a00e75fc0ed7f897404c1c7d607b8f986418371267b042de0384b27ef9.jpg"}, {"id": "r4", "title": "تلاوة وهدوء (وضع صامت للموسيقى) 📖", "category": "قرآن", "cover": "assets/54e916da3ef118b4b2be0f374b01afba2f3338b325b76807d36341691e7d6b3d.jpg"}, {"id": "r5", "title": "غرفة الأصدقاء - دردشة مسائية ☕", "category": "دردشة", "cover": "assets/0bbde3a00e75fc0ed7f897404c1c7d607b8f986418371267b042de0384b27ef9.jpg"}, {"id": "r6", "title": "غرفتي الخاصة — هلاا VIP ✨", "category": "دردشة", "cover": "assets/62cb9f56bd3f374f74ce234cd923cb19b938399264efe04a9ade8ff47fda1d80.jpg"}];
for(const r of rooms){
  const btn=document.createElement('button');btn.className='room';
  const img=new Image();img.src=r.cover;img.alt='';img.loading='lazy';
  const title=document.createElement('strong'),category=document.createElement('small');
  title.textContent=r.title;category.textContent='⌂ '+r.category;btn.append(img,title,category);btn.onclick=()=>join(r);$('.rooms').append(btn);
}
const tabs=[['games','🎮','الألعاب'],['rooms','⌂','الغرف'],['moments','✎','اللحظات'],['messages','✉','الرسائل']];
function selectTab(id){
  $('#games').hidden=id!=='games';$('#activities').hidden=!['games','rooms'].includes(id);$('#more').hidden=id==='rooms';
  [...$('.rooms').children].forEach((el,i)=>el.hidden=id==='games'&&i>=4);
  $('#empty').hidden=['games','rooms'].includes(id);
  $('#empty h2').textContent=tabs.find(t=>t[0]===id)[2];
  $('#empty p').textContent=id==='messages'?'لم تصلك رسائل بعد.':'لا توجد لحظات منشورة.';
  for(const b of $('nav').children)b.setAttribute('aria-current',b.dataset.id===id?'page':'false');
  window.scrollTo(0,0);
}
for(const [id,icon,label] of tabs){
  const b=document.createElement('button');b.dataset.id=id;const mark=document.createElement('b');mark.textContent=icon;mark.ariaHidden='true';
  b.append(mark,label);b.onclick=()=>selectTab(id);$('nav').append(b);
}
$('#more').onclick=()=>selectTab('rooms');
function lobby(){ $('#lobby').hidden=false;$('nav').hidden=false;selectTab(view==='rooms'?'rooms':'games'); }
function endVoice(){generation++;const old=voice;voice=null;if(old)old.destroy();$('#mount').replaceChildren();if($('#voice').open)$('#voice').close();}
$('#leave').onclick=endVoice;$('#voice').oncancel=e=>{e.preventDefault();endVoice();};
let zegoLoad;
function loadVoice(){
  if(!zegoLoad)zegoLoad=new Promise((resolve,reject)=>{
    const script=document.createElement('script');script.src='https://unpkg.com/@zegocloud/zego-uikit-prebuilt/zego-uikit-prebuilt.js';
    script.onload=()=>resolve(window.ZegoUIKitPrebuilt);script.onerror=()=>{zegoLoad=null;reject(Error());};document.head.append(script);
  });return zegoLoad;
}
async function join(room){
  if(!user){go('login');return;}
  const attempt=++generation;$('#voiceTitle').textContent=room.title;$('#voiceStatus').textContent='جارٍ الاتصال بالغرفة…';$('#voice').showModal();
  try{
    const {data,error}=await client.functions.invoke('zego-token',{body:{room:room.id}});if(error)throw error;
    const kit=await loadVoice();if(attempt!==generation)return;
    const name=user.user_metadata?.nickname||'عضو '+user.id.slice(0,5);
    voice=kit.create(kit.generateKitTokenForProduction(data.appID,data.token,data.roomID,data.userID,name));
    const role=['owner','moderator'].includes(data.role)?kit.Host:data.role==='speaker'?kit.Cohost:kit.Audience;
    voice.joinRoom({container:$('#mount'),scenario:{mode:kit.LiveStreaming,config:{role}},turnOnCameraWhenJoining:false,turnOnMicrophoneWhenJoining:false,showMyCameraToggleButton:false,showScreenSharingButton:false,showPreJoinView:false,showLeavingView:false,onJoinRoom:()=>$('#voiceStatus').textContent='',onLeaveRoom:()=>{if(attempt===generation)endVoice();}});
  }catch{if(attempt===generation)$('#voiceStatus').textContent='تعذر الاتصال بالغرفة. تحقق من تأكيد حسابك والاتصال ثم أعد المحاولة.';}
}
if(Object.hasOwn(authModes,view))authScreen(view);
else if(view==='guest')lobby();
else sdk.then(async c=>{if(c&&(await c.auth.getSession()).data.session)lobby();else location.replace('studio/');});
