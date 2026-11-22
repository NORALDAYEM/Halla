# Halaa Voice Server (ZEGOCLOUD + LiveKit)

## إعداد السيرفر الصوتي عبر ZEGOCLOUD (AppID: 400719759)
1. افتح لوحة تحكم **ZEGOCLOUD Console** للمشروع `400719759` وانسخ مفتاح **ServerSecret** (مكون من 32 حرفاً).
2. عند النشر على **Render** أو **VPS**، أضف متغيرات البيئة التالية:
   - `ZEGO_APP_ID=400719759`
   - `ZEGO_SERVER_SECRET=ضع_مفتاح_ServerSecret_هنا`
   - `PORT=3000`
3. شغّل الخادم:
   ```bash
   npm install
   npm start
   ```
4. سيعمل التطبيق عبر الرابط `http://localhost:3000` (أو رابط Render) وسيقوم الخادم بتوليد **Token04** آمن تلقائياً لكل غرفة صوتية عبر المسار `POST /api/zego-token`.
