import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/project.dart';

/// صف أفاتارات الفريق (Initials بدائرة ملوّنة) مع تراكب بسيط،
/// وبيظهر "+N" إذا في أعضاء أكتر من اللي بنقدر نعرضهم
class TeamAvatars extends StatelessWidget {
  final List<TeamMember> members;
  final int totalCount;
  final double size;
  final int maxVisible;

  const TeamAvatars({
    super.key,
    required this.members,
    required this.totalCount,
    this.size = 30,
    this.maxVisible = 4,
  });

  @override
  Widget build(BuildContext context) {
    final visible = members.take(maxVisible).toList();
    final overflow = totalCount - visible.length;

    return SizedBox(
      height: size,
      child: Stack(
        children: [
          for (int i = 0; i < visible.length; i++)
            Positioned(
              left: i * (size * 0.68),
              child: _Avatar(member: visible[i], size: size),
            ),
          if (overflow > 0)
            Positioned(
              left: visible.length * (size * 0.68),
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEDEFF1),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  '+$overflow',
                  style: TextStyle(
                    fontSize: size * 0.32,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkCharcoal,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final TeamMember member;
  final double size;

  const _Avatar({required this.member, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: member.color,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        member.initials,
        style: TextStyle(
          fontSize: size * 0.32,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
