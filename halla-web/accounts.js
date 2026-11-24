// The account module owns authentication and the user's session. Private user records stay in Supabase Auth.
window.HallaAccounts = (() => {
  const base = new URL('.', document.currentScript.src);
  const endpoint = 'https://uwjrboviicypyhregpoo.supabase.co';
  const publicKey = 'sb_publishable_QbUKNVMYDRK63NjB26tCtw_jzOaEXdR';
  const member = new URL('member.html', base);
  let sdk;
  function client() {
    if (!sdk) sdk = import('https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.49.4/+esm')
      .then(({createClient}) => createClient(endpoint,publicKey,{auth:{flowType:'pkce',detectSessionInUrl:!new URL(location.href).searchParams.has('account_return')}}))
      .catch(error=>{sdk=null;throw error;});
    return sdk;
  }
  async function enabled(provider){
    const response=await fetch(endpoint+'/auth/v1/settings',{headers:{apikey:publicKey},cache:'no-store'});
    if(!response.ok)throw Error('settings');
    return (await response.json()).external?.[provider]===true;
  }
  async function oauth(provider,link){
    if(!['google','facebook'].includes(provider))throw Error('provider');
    const auth=(await client()).auth;
    const redirect=new URL('index.html',base);
    redirect.searchParams.set('account_return',provider);
    const androidFacebook = provider === 'facebook' && /\bHallaFacebook\/1\b/.test(navigator.userAgent);
    const options = {redirectTo: androidFacebook ? 'com.halla.voiceclubs://auth/facebook' : redirect.href};
    if(provider==='google')options.queryParams={prompt:'select_account'};
    const result=link?await auth.linkIdentity({provider,options}):await auth.signInWithOAuth({provider,options});
    if(result.error)throw result.error;
  }
  async function sendCode(phone,link){
    const auth=(await client()).auth;
    const result=link?await auth.updateUser({phone}):await auth.signInWithOtp({phone});
    if(result.error)throw result.error;
  }
  async function verify(phone,token,link){
    const {data,error}=await (await client()).auth.verifyOtp({phone,token,type:link?'phone_change':'sms'});
    if(error||!data.user)throw error||Error('verification');
  }
  function phoneNumber(value){
    let phone=value.trim().replace(/[٠-٩]/g,n=>String('٠١٢٣٤٥٦٧٨٩'.indexOf(n))).replace(/[\s()-]/g,'').replace(/^00/,'+');
    if(/^05\d{8}$/.test(phone))phone='+966'+phone.slice(1);
    return /^\+[1-9]\d{7,14}$/.test(phone)?phone:'';
  }
  async function passwordRequest(mode,mail,password,nickname){
    const instance=await client();

      const redirect=new URL(member.href);
      let result;
      if(mode==='reset'){redirect.search='?view=recover';result=await instance.auth.resetPasswordForEmail(mail,{redirectTo:redirect.href});}
      else if(mode==='signup')result=await instance.auth.signUp({email:mail,password,options:{data:{nickname},emailRedirectTo:redirect.href}});
      else if(mode==='recover')result=await instance.auth.updateUser({password});
      else result=await instance.auth.signInWithPassword({email:mode==='username'?localStorage.getItem('halla.alias.'+nickname.toLowerCase())||'':mail,password});
    return result;
  }
  return {base,member,client,enabled,oauth,sendCode,verify,phoneNumber,passwordRequest};
})();
