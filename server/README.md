# Halaa Voice Server (ZEGOCLOUD + LiveKit)
خادم الصوتيات لتطبيق هلا لإصدار رموز المصادقة وإدارة الغرف الصوتية عبر ZEGOCLOUD و LiveKit.

## إعداد السيرفر الصوتي عبر ZEGOCLOUD (AppID: 828861219)
1. افتح لوحة تحكم **ZEGOCLOUD Console** للمشروع `828861219` وأدخل مفتاح **ServerSecret** مباشرة في إعدادات الخادم دون مشاركته.
2. عند النشر على **Render** أو **VPS**، أضف متغيرات البيئة التالية:
   - `ZEGO_APP_ID=828861219`
   - `ZEGO_SERVER_SECRET=ضع_مفتاح_ServerSecret_هنا`
   - استخدم `PORT` الذي يوفّره Render؛ القيمة المحلية الافتراضية 3000.
3. شغّل الخادم:
   ```bash
   npm install
   npm start
   ```
4. سيعمل التطبيق عبر الرابط `http://localhost:3000` (أو رابط Render) وسيقوم الخادم بتوليد **Token04** آمن تلقائياً لكل غرفة صوتية عبر المسار `POST /api/zego-token`.

راجع [حالة التكامل وحدود الاختبار](ZEGO_REVIEW.md) قبل تجربة الحساب أو إطلاق تحديث للهواتف.
