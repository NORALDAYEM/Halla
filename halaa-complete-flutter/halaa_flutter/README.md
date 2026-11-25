# هلاا — المشروع الموحّد الكامل بلغة Flutter (التطبيق + لوحة الإدارة)

مشروع **Flutter / Dart** موحّد يجمع:
1. **تطبيق هلاا (`ENTRY=app`):** نفس الخلفيات الـ 7 الحقيقية (`welcome-gallery`) والتصميم الزجاجي المعتمد (زر وضع الضيف الأصفر، زر جوجل السماوي بشارة `آخر تسجيل دخول`، زر Facebook الزجاجي، الدوائر الثلاث السماوية الداكنة السفلية، وبطاقات الألعاب الحقيقية للشطرنج والليدو والبلياردو والضومينو).
2. **لوحة إدارة هلاا (`ENTRY=admin`):** نفس الخلفيات والتصميم الزجاجي بشاشة دخول واحدة (حقول فارغة، `ADMIN` / `12345678`) و8 تبويبات تحكم كاملة.

## النشر التلقائي على GitHub Pages وIDrive e2
1. فك ضغط `halaa-complete-flutter.zip` وارفع مجلد `halaa_flutter/` وملف `.github/workflows/deploy-flutter-halla.yml` إلى جذر مستودع `NORALDAYEM/Halla` على الفرع `main`.
2. من تبويب **Actions** شغّل **Build & Deploy Full Halaa Flutter (App + Admin)**؛ سيبني GitHub نسختي Flutter للويب ويضعهما في `halla-web/` و`admin/` تلقائياً مع الحفاظ على مجلد الصور `halla-web/assets/welcome-gallery/`، ثم تُحفظ النسخة تلقائياً في سحابة IDrive e2.
