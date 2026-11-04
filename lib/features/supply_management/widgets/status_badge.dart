import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case 'Approved':
        bg = const Color(0xFFDCFCE7);
        fg = AppTheme.approvedGreen;
        icon = Icons.check_circle_outline;
        break;
      case 'Temporary':
        bg = const Color(0xFFFEF3C7);
        fg = AppTheme.temporaryAmber;
        icon = Icons.hourglass_top_outlined;
        break;
      case 'Not Recommended':
        bg = const Color(0xFFFEE2E2);
        fg = AppTheme.notRecommendedRed;
        icon = Icons.cancel_outlined;
        break;
      case 'Non-existing':
        bg = const Color(0xFFF1F5F9);
        fg = AppTheme.nonExistingGrey;
        icon = Icons.do_not_disturb_on_outlined;
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = AppTheme.textMuted;
        icon = Icons.info_outline;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: fg),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: fg,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
