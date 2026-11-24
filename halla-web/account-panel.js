(() => {
  const accounts=window.HallaAccounts, url=new URL(location.href);
  const dialog=document.createElement('dialog'); dialog.id='account-panel';dialog.setAttribute('aria-labelledby','account-heading');
  dialog.innerHTML='<h2 id="account-heading"></h2><p class="info" role="status"></p><form><label hidden>رقم الهاتف مع مفتاح الدولة<input name="phone" type="tel" dir="ltr" placeholder="+9665…" autocomplete="tel"></label><label hidden>رمز التحقق<input name="code" inputmode="numeric" dir="ltr" autocomplete="one-time-code" maxlength="10"></label><button class="primary" type="submit" hidden></button></form><button class="again" type="button" hidden>تغيير الرقم</button><a class="share" target="_blank" rel="noopener noreferrer" hidden>مشاركة دعوة هلاا على فيسبوك</a><a class="mail" hidden>الدخول بالبريد</a><button class="close" type="button">إغلاق</button>';
  document.body.append(dialog);
  const q=s=>dialog.querySelector(s),form=q('form'),fields=form.elements,action=q('[type=submit]'),again=q('.again'),mail=q('.mail');
  mail.href=accounts.member.href+'?view=login';
  q('.share').href='https://www.facebook.com/sharer/sharer.php?u='+encodeURIComponent(accounts.base.href);
  let mode='',step='',phone='',link=false,sequence=0;
  const names={google:'Google',facebook:'فيسبوك',phone:'الهاتف'};
  function show(title){
    sequence++;form.reset();phone='';step='';q('h2').textContent=title;q('.info').textContent='';
    for(const el of [action,again,mail,q('.share'),...form.querySelectorAll('label')])el.hidden=true;
    action.disabled=false;fields.phone.required=false;fields.code.required=false;
    if(!dialog.open)dialog.showModal();
    return sequence;
  }
  function submitLabel(text){action.textContent=text;action.hidden=false;}
  function phoneStep(code){
    step=code?'verify':'send';fields.phone.parentElement.hidden=code;fields.phone.required=!code;
    fields.code.parentElement.hidden=!code;fields.code.required=code;again.hidden=!code;
    submitLabel(code?'تحقق ومتابعة':'إرسال رمز التحقق');(code?fields.code:fields.phone).focus();
  }
  function close(){dialog.close();}
  q('.close').onclick=close;
  dialog.addEventListener('close',()=>{sequence++;if(step==='finished')location.replace(accounts.member.href);});
  async function open(provider){
    if(!names[provider])return;
    mode=provider;const seq=show('الدخول أو الربط عبر '+names[provider]);q('.info').textContent='جارٍ التحقق من توفر الخدمة…';
    try{
      if(!await accounts.enabled(provider)){
        if(seq!==sequence)return;
        q('.info').textContent=provider==='phone'?'خدمة الرسائل النصية لم تُفعّل بعد.':'الدخول عبر '+names[provider]+' لم يُفعّل بعد.';
        mail.hidden=false;return;
      }
      const {data,error}=await (await accounts.client()).auth.getSession();
      if(seq!==sequence)return;if(error)throw error;
      link=Boolean(data.session);
      if(url.searchParams.get('link')==='1'&&!link){q('.info').textContent='سجّل الدخول إلى حساب هلاا أولًا لإضافة وسيلة دخول إليه.';mail.hidden=false;return;}
      if(provider==='phone'){q('.info').textContent='سنرسل رمزًا للتحقق من ملكية الرقم.';phoneStep(false);}
      else if(/; wv\)/i.test(navigator.userAgent)&&link){q('.info').textContent='للربط افتح حساب هلاا نفسه في متصفح الهاتف، ثم اختر وسيلة الربط من حسابي.';}else if(/; wv\)/i.test(navigator.userAgent)){
        q('.info').textContent='لمتابعة اختيار الحساب في متصفح الهاتف، انسخ الرابط وافتحه في Chrome. سيكتمل الدخول هناك.';
        step='browser';submitLabel('نسخ رابط الدخول');
      }else{
        q('.info').textContent=provider==='google'?'اختر حسابك من شاشة Google الآمنة.':'تابع إلى فيسبوك للموافقة على ربط حسابك.';
        step='oauth';submitLabel(link?'ربط الحساب':'اختيار الحساب');
      }
    }catch{if(seq===sequence){q('.info').textContent='تعذر الاتصال بخدمة الحسابات. أعد المحاولة.';mail.hidden=false;}}
  }
  again.onclick=()=>{phone='';fields.code.value='';q('.info').textContent='أدخل رقم الهاتف.';phoneStep(false);};
  form.onsubmit=async e=>{
    e.preventDefault();if(action.disabled)return;
    const seq=sequence;action.disabled=true;again.disabled=true;
    try{
      if(step==='browser'){
        const address=new URL('index.html',accounts.base);address.searchParams.set('account',mode);
        try{await navigator.clipboard.writeText(address.href);q('.info').textContent='تم نسخ الرابط. افتحه في متصفح الهاتف.';}
        catch{q('.info').textContent=address.href;}return;
      }
      if(step==='oauth'){await accounts.oauth(mode,link);return;}
      if(step==='send'){
        phone=accounts.phoneNumber(fields.phone.value);
        if(!phone){q('.info').textContent='أدخل رقمًا صالحًا مع مفتاح الدولة.';return;}
        await accounts.sendCode(phone,link);if(seq!==sequence)return;
        q('.info').textContent='أدخل الرمز المرسل إلى '+phone;phoneStep(true);
      }else if(step==='verify'){
        const code=fields.code.value.trim().replace(/[٠-٩]/g,n=>String('٠١٢٣٤٥٦٧٨٩'.indexOf(n)));
        if(!/^\d{4,10}$/.test(code)){q('.info').textContent='تحقق من الأرقام المكتوبة.';return;}
        await accounts.verify(phone,code,link);if(seq===sequence)location.replace(accounts.member.href);
      }
    }catch{if(seq===sequence)q('.info').textContent='تعذّرت المتابعة. تحقق من البيانات أو أعد المحاولة لاحقًا.';}
    finally{if(seq===sequence){action.disabled=false;again.disabled=false;}}
  };
  for(const b of document.querySelectorAll('[data-provider]'))b.onclick=()=>open(b.dataset.provider.toLowerCase());
  for(const a of document.querySelectorAll('a[href$="?view=phone"]'))a.onclick=e=>{e.preventDefault();open('phone');};
  const provider=url.searchParams.get('account_return');
  if(provider && ['google','facebook'].includes(provider)){
    const seq=show('العودة إلى هلاا');q('.info').textContent='جارٍ تأكيد الحساب…';
    (async()=>{
      try{
        if(url.searchParams.has('error')||new URLSearchParams(url.hash.slice(1)).has('error')||!url.searchParams.has('code'))throw Error();
        const auth=(await accounts.client()).auth;
        const {data,error}=await auth.exchangeCodeForSession(url.searchParams.get('code'));
        if(error||!data.user?.identities?.some(i=>i.provider===provider))throw Error();
        if(seq!==sequence)return;
        if(provider==='google'){location.replace(accounts.member.href);return;}
        step='finished';q('h2').textContent='تم الدخول عبر فيسبوك';q('.info').textContent='يمكنك دعوة أصدقائك للانضمام إلى هلاا.';
        q('.share').hidden=false;q('.close').textContent='متابعة إلى هلاا';
      }catch{if(seq===sequence){q('.info').textContent='تعذر إكمال الربط أو تم إلغاؤه. يمكنك المحاولة من جديد.';mail.hidden=false;}}
      finally{history.replaceState(null,'',url.pathname);}
    })();
  }else if(url.searchParams.has('account'))open(url.searchParams.get('account'));
})();
