import 'package:flutter/material.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';
import 'package:melora_music/theme/app_text_styles.dart';

/// Prototype 5-band equalizer bottom sheet.
class EqualizerSheet extends StatefulWidget {
  const EqualizerSheet({super.key});

  @override
  State<EqualizerSheet> createState() => _EqualizerSheetState();
}

class _EqualizerSheetState extends State<EqualizerSheet> {
  static const _bands = ['60Hz', '230Hz', '910Hz', '4kHz', '14kHz'];
  static const _labels = ['Bass', 'Low-Mid', 'Mid', 'High-Mid', 'Treble'];
  final List<double> _values = [0.6, 0.4, 0.5, 0.55, 0.45];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scroll) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg),
            ),
          ),
          child: SingleChildScrollView(
            controller: scroll,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Text('Equalizer', style: AppTextStyles.headlineMedium),
                      const Spacer(),
                      Switch(
                        value: true,
                        onChanged: (_) {},
                        activeThumbColor: AppColors.accentViolet,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(_bands.length, (i) {
                      return Column(
                        children: [
                          Text(
                            '${((_values[i] - 0.5) * 24).round()}dB',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.accentVioletLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 140,
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: Slider(
                                value: _values[i],
                                onChanged: (v) =>
                                    setState(() => _values[i] = v),
                              ),
                            ),
                          ),
                          Text(_bands[i], style: AppTextStyles.caption),
                          const SizedBox(height: 2),
                          Text(
                            _labels[i],
                            style: AppTextStyles.caption.copyWith(fontSize: 9),
                          ),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: ['Flat', 'Bass Boost', 'Vocal', 'Pop', 'Rock']
                        .map(
                          (preset) => GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull,
                                ),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                preset,
                                style: AppTextStyles.labelMedium,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
