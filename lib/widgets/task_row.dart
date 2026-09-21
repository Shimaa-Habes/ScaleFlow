import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/dash_text_styles.dart';
import '../models/task_item.dart';

/// صف مهمة واحدة (checkbox + عنوان + تاريخ الاستحقاق + نقطة ملوّنة
/// حسب الأولوية) — نفس المكون مستخدم بـ Priority Tasks (Home)
/// وبـ Upcoming Tasks (Project Details)
class TaskRow extends StatefulWidget {
  final TaskItem task;

  const TaskRow({super.key, required this.task});

  @override
  State<TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<TaskRow> {
  late bool _isDone = widget.task.isDone;

  @override
  Widget build(BuildContext context) {
    final color = widget.task.urgency.color;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isDone = !_isDone),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: _isDone ? AppColors.statusGreen : const Color(0xFFC7CDD2),
                  width: 1.6,
                ),
                color: _isDone ? AppColors.statusGreen : Colors.transparent,
              ),
              child: _isDone
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task.title,
                  style: DashTextStyles.label(size: 14).copyWith(
                    decoration:
                        _isDone ? TextDecoration.lineThrough : null,
                    color: _isDone
                        ? const Color(0xFFA9B0B6)
                        : AppColors.darkCharcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(widget.task.dueLabel, style: DashTextStyles.caption()),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ],
      ),
    );
  }
}
