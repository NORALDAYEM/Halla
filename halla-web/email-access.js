(() => {
  const dialog = document.getElementById('email-access');
  const form = dialog.querySelector('form');
  const fields = form.elements;
  const title = dialog.querySelector('h2');
  const status = dialog.querySelector('[role=status]');
  const submit = form.querySelector('[type=submit]');
  let mode;
  let generation = 0;

  function open(next) {
    generation++;
    mode = next;
    form.reset();
    fields.confirmation.setCustomValidity('');
    status.textContent = '';
    const signup = mode === 'signup';
    for (const field of form.querySelectorAll('[data-signup]')) {
      field.hidden = !signup;
      const input = field.querySelector('input, select');
      input.disabled = !signup;
      input.required = signup;
    }
    fields.password.autocomplete = signup ? 'new-password' : 'current-password';
    fields.password.minLength = signup ? 10 : 1;
    title.textContent = signup ? 'تسجيل حساب جديد' : 'تسجيل الدخول';
    submit.textContent = signup ? 'تسجيل' : 'تسجيل الدخول';
    submit.disabled = false;
    dialog.showModal();
    (signup ? fields.nickname : fields.email).focus();
  }

  document.querySelectorAll('[data-email-mode]').forEach(button => {
    button.addEventListener('click', () => open(button.dataset.emailMode));
  });
  dialog.querySelector('[data-dismiss]').onclick = () => dialog.close();
  dialog.addEventListener('close', () => {
    generation++;
    form.reset();
  });
  form.addEventListener('input', () => fields.confirmation.setCustomValidity(''));
  form.addEventListener('submit', async event => {
    event.preventDefault();
    if (submit.disabled) return;
    const signup = mode === 'signup';
    if (signup && fields.password.value !== fields.confirmation.value) {
      fields.confirmation.setCustomValidity('أعد كتابة كلمة المرور نفسها.');
      fields.confirmation.reportValidity();
      return;
    }
    const request = generation;
    submit.disabled = true;
    status.style.color = ''; status.style.fontWeight = ''; status.textContent = 'جارٍ التحقق…';
    try {
      const result = await HallaAccounts.passwordRequest(mode, fields.email.value.trim(),
        fields.password.value, fields.nickname.value.trim(), fields.gender.value, fields.country.value);
      if (request !== generation) return;
      if (result.error) throw result.error;
      if (result.data?.session) {
        location.replace(HallaAccounts.member.href);
      } else if (signup) {
        form.reset();
        status.textContent = 'راجع بريدك الإلكتروني لتأكيد الحساب ثم سجّل الدخول.';
      } else {
        throw Error('missing session');
      }
    } catch (error) {
      if (request !== generation) return;
    status.style.color = '#dc2626'; status.style.fontWeight = '700';   status.textContent = error.code === 'email_not_confirmed' ? 'أكّد بريدك الإلكتروني أولًا.' :
        signup ? 'تعذّر التسجيل. راجع البيانات والاتصال ثم حاول مجددًا.' :
        'اسم المستخدم أو كلمة المرور غير صحيحة';
    } finally {
      if (generation === request) submit.disabled = false;
    }
  });
  const entry = new URLSearchParams(location.search).get('email');
  if (entry === 'login' || entry === 'signup') open(entry);
})();
