import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

enum SarvButtonVariant { primary, secondary, outlined, destructive }

/// Standardized action button for SARV MANGAL
class SarvButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final SarvButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const SarvButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SarvButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || isLoading;

    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case SarvButtonVariant.primary:
        bg = disabled ? AppColors.textMuted.withValues(alpha: 0.4) : AppColors.primary;
        fg = Colors.white;
        break;
      case SarvButtonVariant.secondary:
        bg = disabled ? AppColors.textMuted.withValues(alpha: 0.4) : AppColors.secondary;
        fg = AppColors.textPrimary;
        break;
      case SarvButtonVariant.outlined:
        bg = Colors.transparent;
        fg = disabled ? AppColors.textMuted : AppColors.primary;
        border = BorderSide(color: fg, width: 1.5);
        break;
      case SarvButtonVariant.destructive:
        bg = disabled ? AppColors.textMuted.withValues(alpha: 0.4) : AppColors.error;
        fg = Colors.white;
        break;
    }

    Widget content = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(color: fg),
              ),
            ],
          );

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: bg,
        borderRadius: AppSpacing.roundedMd,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: AppSpacing.roundedMd,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: AppSpacing.roundedMd,
              border: border != BorderSide.none ? Border.fromBorderSide(border) : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: content,
          ),
        ),
      ),
    );
  }
}
