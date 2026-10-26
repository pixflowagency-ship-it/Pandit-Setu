import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Semantic status badge for SARV MANGAL
class SarvStatusBadge extends StatelessWidget {
  final String status;

  const SarvStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    final upper = status.toUpperCase();

    if (upper.contains('APPROV') ||
        upper.contains('COMPLET') ||
        upper.contains('ACTIV') ||
        upper.contains('CONFIRM')) {
      bg = AppColors.successLight;
      fg = AppColors.success;
    } else if (upper.contains('PEND') ||
        upper.contains('WAIT') ||
        upper.contains('SCHEDUL') ||
        upper.contains('IN_TRANSIT')) {
      bg = AppColors.warningLight;
      fg = AppColors.warning;
    } else if (upper.contains('REJECT') ||
        upper.contains('CANCEL') ||
        upper.contains('FAIL') ||
        upper.contains('EXPIRE')) {
      bg = AppColors.errorLight;
      fg = AppColors.error;
    } else {
      bg = AppColors.surfaceWarm;
      fg = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppSpacing.roundedPill,
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        upper,
        style: AppTypography.labelMedium.copyWith(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
