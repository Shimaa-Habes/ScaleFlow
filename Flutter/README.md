# ScaleFlow — Login, Register, Home & Project Details

تصميم شاشات ScaleFlow (تسجيل الدخول، إنشاء حساب، الرئيسية، تفاصيل المشروع)
باستخدام Flutter/Dart، بنفس الهوية البصرية ونظام الألوان الرسمي من Figma.

## هيكلية المشروع

```
lib/
├── main.dart                       # نقطة الدخول + كل الـ routes
├── core/
│   ├── app_colors.dart             # كل الألوان (auth + نظام الألوان الرسمي الجديد)
│   ├── app_text_styles.dart        # خطوط شاشات auth
│   └── dash_text_styles.dart       # خطوط Inter لشاشات الـ Dashboard (Home/Details)
├── models/
│   ├── project.dart                # موديل المشروع + حالة On Track/At Risk
│   └── task_item.dart              # موديل المهمة + مستوى الأولوية/اللون
├── data/
│   └── mock_data.dart              # بيانات وهمية (مشاريع، مهام، المستخدم الحالي)
├── widgets/
│   ├── custom_text_field.dart، password_requirement_item.dart، scaleflow_logo.dart
│   ├── health_ring.dart            # حلقة نسبة صحة المشروع (ملوّنة حسب النسبة)
│   ├── stat_chip.dart              # كرت إحصائية صغير ملوّن (Today's Overview...)
│   ├── ai_insight_card.dart        # كرت "ScaleFlow AI Insight" البنفسجي
│   ├── task_row.dart               # صف مهمة (checkbox + نقطة أولوية ملوّنة)
│   ├── project_card.dart           # كرت مشروع مصغّر (My Projects) — قابل للضغط
│   ├── team_avatars.dart           # صف أفاتارات الفريق مع +N
│   └── scaleflow_bottom_nav.dart   # شريط التنقل السفلي (Home/Projects/Dashboard/AI/Profile)
└── screens/
    ├── register_screen.dart        # Create your account
    ├── login_screen.dart           # Welcome back
    ├── forgot_password_screen.dart # استرجاع كلمة السر
    ├── home_screen.dart            # الشاشة الرئيسية (Dashboard)
    └── project_details_screen.dart # تفاصيل مشروع محدد
```

## التنقل (Navigation)

- بعد تسجيل دخول أو إنشاء حساب ناجح (mock) → ينتقل تلقائياً لشاشة `/home`.
- الضغط على أي كرت مشروع بـ "My Projects" (أو تبويب "Projects" بالشريط السفلي)
  → يفتح `ProjectDetailsScreen` لنفس المشروع (البيانات ممررة عبر الـ constructor،
  مش عبر route مركزي، لتفادي أي تعقيد إضافي بهالمرحلة).
- زر الرجوع (←) بشاشة Project Details → `Navigator.pop()` يرجعك عالـ Home.

## نظام الألوان الرسمي (من Figma "Color system")

كل الألوان موجودة بـ `app_colors.dart` تحت قسم منفصل، بنفس القيم الست‑عشرية
بالضبط اللي بالتصميم:

| اللون | Hex | الاستخدام |
|---|---|---|
| Dark charcoal | `#2C2D30` | نصوص أساسية، عناوين، أيقونات |
| Purple | `#6C5CE7` | AI، insights، تقدّم أساسي |
| Green | `#61BD4F` | صحي، نجاح، مكتمل، On Track |
| Cyan | `#26C6DA` | بيانات، معلومات، مشاريع نشطة |
| Yellow | `#F2D600` | مهم، قيد المعالجة، Due Today |
| Pink | `#EB5A9A` | مستخدمين، أفاتارات |
| Coral | `#FF6B4A` | تنبيهات، خطر، Overdue |
| White | `#FFFFFF` | خلفية أساسية، سطح الكروت |

كل كرت/أيقونة بشاشتي Home وProject Details مربوطة باللون الدلالي المناسب
إلها (مثلاً: Team = Pink، Tasks = Cyan، Days Left = Yellow، Overdue = Coral...).

## اسم المستخدم بالتحية

`"Good morning, {firstName} 👋"` — الاسم ديناميكي فعلياً، مش Hardcoded:
- لما تعملي **Register** باسمك، بينحفظ وبيصير هو اسم شاشة الـ Home فوراً.
- لما تسجّلي **Login** بحساب موجود، بيرجع اسم صاحب هاد الحساب بالذات.
- الاسم المعروض هو أول كلمة بس من الاسم الكامل (`CurrentUser.firstName`
  بملف `lib/data/mock_data.dart`)، مثلاً "Lama Khaled" → "Lama".

لما يترابط مع الـ Backend الحقيقي، بس بدّلوا جسم `CurrentUser.register()`
و`CurrentUser.login()` بنداء API حقيقي (التعليق `TODO (Backend track)`
موجود بنفس المكان بالضبط) — باقي الشاشات ما رح تحتاج أي تعديل.

## بيانات وهمية (Mock Data)

كل بيانات المشاريع والمهام بملف `lib/data/mock_data.dart`، مفصولة تماماً عن
الشاشات نفسها. لما يجهز الـ Backend، بدّل `MockData.projects` (وقيم
`Today's Overview`) بنداء API حقيقي — الشاشات نفسها ما رح تحتاج تتغيّر لأنها
بتستهلك نفس الـ `Project`/`TaskItem` models.



## طريقة التشغيل على VS Code / Chrome

1. تأكد إنو Flutter SDK مثبت (`flutter --version`).
2. افتح مجلد `scaleflow_auth` بـ VS Code.
3. بالتيرمنال:
   ```bash
   flutter pub get
   flutter run -d chrome
   ```
4. الشاشة الافتراضية هي `Register`. تقدر تنقل بين الشاشتين من الرابط
   بالأسفل ("Log in" / "Create one") داخل التطبيق مباشرة.

## ملاحظات مهمة

- **الحالات (Validation States) المطبّقة:**
  - الإيميل: تتحقق من صيغته وتظهر رسالة خطأ حمراء أو أيقونة صح خضراء.
  - كلمة السر (شاشة التسجيل): شروط تتحدّث لحظياً أثناء الكتابة (8+ أحرف، حرف كبير، رقم).
  - تأكيد كلمة السر: تتحقق من التطابق مع كلمة السر الأصلية.
  - حقول تسجيل الدخول: رسالة خطأ عند الضغط على "Log In" وأحد الحقول فاضي.
    بعد اجتياز التحقق من الشكل، بيتحقق من الإيميل/كلمة السر مقابل **حسابات
    محفوظة بالذاكرة (mock auth store)** بملف `lib/data/mock_data.dart`
    (كلاس `CurrentUser`) — لحد ما يجهز الـ Backend الفعلي:
    - أي حساب تعمليه بشاشة Register بينحفظ فعلياً وبتقدري تسجّلي فيه
      دخول مباشرة بعدها.
    - في كمان حساب تجريبي جاهز مسبقاً: Email: `test@scaleflow.com` —
      Password: `Test1234`.
    - **ملاحظة:** هاي الحسابات بالذاكرة بس (RAM)، يعني بتنمسح لما تسكّري
      وتفتحي التطبيق من جديد (hot restart أو إعادة تشغيل) — هاد طبيعي
      ومتوقع لحد ما نربطها بقاعدة بيانات حقيقية.

    أي بيانات غلط بتظهر "Invalid email or password" فوق الزر، متل
    التطبيقات الحقيقية. لما يجهز الـ API، دوروا على تعليق
    `TODO (Backend track)` بأعلى `CurrentUser.register()`/`login()`
    بملف `mock_data.dart` واستبدلوهم بنداء API فعلي.
- **إظهار/إخفاء كلمة السر:** أيقونة عين بكل حقل باسورد (`CustomTextField(isPassword: true)`).
- **التصميم المتجاوب (Responsive):** استخدمنا `LayoutBuilder` + `ConstrainedBox`
  بحيث المحتوى بياخد أقصى عرض 420px على الشاشات الكبيرة (تابلت/ويب)،
  ويمتد بشكل طبيعي على شاشات الموبايل الصغيرة، مع `SingleChildScrollView`
  لتفادي مشاكل الـ overflow لما يفتح الكيبورد.
- **اللوغو:** حالياً مرسوم بـ `CustomPainter` كبديل مؤقت (placeholder) لحد ما
  يوصلكم ملف اللوغو الرسمي (SVG/PNG) من فريق الـ UI/UX — وقتها بس بدّل
  محتوى `ScaleFlowLogo` بصورة `Image.asset(...)`.
- **الخط:** الكود معتمد على خط `Roboto` الافتراضي. إذا فريق التصميم حدد خط
  معيّن بالـ design system (مثلاً Poppins/Inter)، ضيفوه بمجلد `fonts/`
  وسجّلوه بـ `pubspec.yaml` تحت `flutter: fonts:`.
- **الألوان:** كل الألوان مجمّعة بملف `app_colors.dart` — أي تعديل مستقبلي
  على الهوية البصرية بصير بمكان واحد بس.

## الخطوة الجاية (اختياري)

- ربط الشاشتين بـ state management (Provider/Bloc/Riverpod) حسب المعمارية
  المتفق عليها مع فريق الـ Backend.
- ربط `Forgot password?` بشاشة استرجاع كلمة السر.
- استبدال اللوغو المرسوم بالكود بملف اللوغو الرسمي.
