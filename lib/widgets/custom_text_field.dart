import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text_styles.dart';

/// حقل إدخال موحّد الشكل لكل التطبيق:
/// - Label أعلى الحقل
/// - حدود بتتغيّر لونها حسب الحالة (عادي / فوكس / خطأ / صحيح)
/// - دعم إظهار/إخفاء كلمة السر عبر [isPassword]
/// - دعم رسالة خطأ تحت الحقل عبر [errorText]
class CustomTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? errorText;
  final bool isValid;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.isValid = false,
    this.onChanged,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Color get _borderColor {
    if (widget.errorText != null) return AppColors.fieldBorderError;
    if (widget.isValid) return AppColors.fieldBorderValid;
    if (_isFocused) return AppColors.fieldBorderFocused;
    return AppColors.fieldBorder;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.fieldBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _borderColor, width: 1.4),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.isPassword ? _obscureText : false,
            keyboardType: widget.keyboardType,
            style: AppTextStyles.fieldInput,
            onChanged: widget.onChanged,
            // نفرض LTR صراحةً على مستوى الحقل نفسه (بالإضافة لفرضها عالتطبيق
            // كامل بـ main.dart) حتى المؤشر والحذف/الإضافة يشتغلوا بشكل طبيعي
            // بغض النظر عن اتجاه اللغة المحيطة بالتطبيق.
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTextStyles.fieldPlaceholder,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      splashRadius: 18,
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.placeholder,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureText = !_obscureText),
                    )
                  : (widget.isValid
                      ? const Icon(Icons.check_circle,
                          color: AppColors.fieldBorderValid, size: 20)
                      : null),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
        ],
      ],
    );
  }
}
