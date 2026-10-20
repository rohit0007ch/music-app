import 'package:flutter/material.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';

/// Standard elevated surface card with optional tap feedback.
class MeloraCard extends StatelessWidget {
  const MeloraCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.borderRadius = AppSpacing.radiusMd,
    this.color = AppColors.surfaceElevated,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: AppColors.accentViolet.withValues(alpha: 0.12),
        highlightColor: AppColors.accentViolet.withValues(alpha: 0.06),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
