import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class StatBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory StatBadge.present() {
    return const StatBadge(
      label: 'Present',
      backgroundColor: AppColors.successLight,
      textColor: AppColors.success,
      icon: Icons.check_circle_rounded,
    );
  }

  factory StatBadge.late() {
    return const StatBadge(
      label: 'Late',
      backgroundColor: AppColors.warningLight,
      textColor: AppColors.warning,
      icon: Icons.access_time_rounded,
    );
  }

  factory StatBadge.absent() {
    return const StatBadge(
      label: 'Absent',
      backgroundColor: AppColors.errorLight,
      textColor: AppColors.error,
      icon: Icons.cancel_rounded,
    );
  }

  factory StatBadge.geofenced({required bool isInside}) {
    return StatBadge(
      label: isInside ? 'On Campus' : 'Off Campus',
      backgroundColor: isInside ? AppColors.infoLight : AppColors.errorLight,
      textColor: isInside ? AppColors.info : AppColors.error,
      icon: isInside ? Icons.location_on_rounded : Icons.location_off_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
