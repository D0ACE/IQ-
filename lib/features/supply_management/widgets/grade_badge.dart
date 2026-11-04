import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradeBadge extends StatelessWidget {
  final String? grade;

  const GradeBadge({super.key, required this.grade});

  @override
  Widget build(BuildContext context) {
    if (grade == null || grade == '-') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          '-',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    Color bg;
    Color fg;
    IconData icon;

    switch (grade) {
      case 'Excellent':
        bg = const Color(0xFFDCFCE7);
        fg = AppTheme.gradeExcellent;
        icon = Icons.star;
        break;
      case 'Good':
        bg = const Color(0xFFDBEAFE);
        fg = AppTheme.gradeGood;
        icon = Icons.thumb_up_alt_outlined;
        break;
      case 'Average':
        bg = const Color(0xFFFEF3C7);
        fg = AppTheme.gradeAverage;
        icon = Icons.horizontal_rule;
        break;
      case 'Poor / Review':
      default:
        bg = const Color(0xFFFEE2E2);
        fg = AppTheme.gradePoor;
        icon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            grade!,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
