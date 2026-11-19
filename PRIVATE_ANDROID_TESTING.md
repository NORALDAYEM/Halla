# تجربة هلاا على هاتف Android

هذه نسخة تطوير محلية وليست التطبيق النهائي. لا تتضمن حالياً صوتاً حياً أو ألعاباً جماعية مكتملة أو مدفوعات فعلية.

## بناء التطبيقين من GitHub

1. افتح https://github.com/NORALDAYEM/Halla/actions
2. افتح **Android APK (private phone testing)**.
3. اختر آخر تشغيل ناجح بعلامة خضراء، ثم نزّل **Halaa-Private-Phone-APKs** من قسم Artifacts.
4. فك ضغط ZIP على هاتفك.
5. ثبّت `Halaa-User-debug.apk` و`Halaa-Admin-debug.apk`. قد تحتاج للسماح بالتثبيت من هذا المصدر في إعدادات Android.

ملف الإدارة واجهة محلية تجريبية ولا يحتوي على تسجيل دخول آمن؛ لا تستخدمه لإدارة بيانات حقيقية.

إذا فشل بناء GitHub Actions، افتح سجل التشغيل لمعرفة الخطأ. وجود إعداد workflow لا يعني نجاح البناء.

## التشغيل من VS Code

```bash
flutter create --platforms=android --project-name halaa .
flutter pub get
flutter run -t lib/main.dart
```

لبناء تطبيق المستخدم: `flutter build apk --debug -t lib/main.dart`.

للاتصال بواجهة API تجريبية لاحقاً: `flutter run --dart-define=HALAA_API_URL=https://YOUR-SERVER -t lib/main.dart`.

لا حاجة إلى نشر التطبيق في متجر عام لتجربته على هاتفك. لكن المزايا الجماعية الحية تتطلب خادماً يمكن للأجهزة الاتصال به.
