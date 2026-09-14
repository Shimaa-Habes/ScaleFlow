# ScaleFlow — Login & Register Screens

تصميم شاشتي "إنشاء حساب" و"تسجيل الدخول" لتطبيق ScaleFlow باستخدام Flutter/Dart،
بنفس الهوية البصرية والألوان والخطوط والـ padding المعتمدة بالتصميم.

## هيكلية المشروع

```
lib/
├── main.dart                     # نقطة الدخول + التنقل بين الشاشتين
├── core/
│   ├── app_colors.dart           # كل الألوان بمكان واحد
│   └── app_text_styles.dart      # كل أنماط الخطوط بمكان واحد
├── widgets/
│   ├── custom_text_field.dart    # حقل إدخال موحّد (عادي/فوكس/خطأ/صحيح + عين كلمة السر)
│   ├── password_requirement_item.dart  # عنصر شرط كلمة السر (✓ أخضر عند التحقق)
│   └── scaleflow_logo.dart       # اللوغو (أيقونة + اسم التطبيق)
└── screens/
    ├── register_screen.dart      # شاشة Create your account
    └── login_screen.dart         # شاشة Welcome back
```

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
