import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';
import 'package:melora_music/theme/app_text_styles.dart';
import 'package:melora_music/viewmodels/player_state.dart';

/// Dialog for choosing a sleep timer duration.
class SleepTimerDialog extends StatefulWidget {
  const SleepTimerDialog({super.key, required this.playerState});
  final PlayerState playerState;

  static const presets = [15, 30, 45, 60];

  @override
  State<SleepTimerDialog> createState() => _SleepTimerDialogState();
}

class _SleepTimerDialogState extends State<SleepTimerDialog> {
  Timer? _ticker;
  final _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Lightweight 1s refresh only while the dialog is open.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.playerState.hasActiveSleepTimer) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _customController.dispose();
    super.dispose();
  }

  void _applyCustom() {
    final parsed = int.tryParse(_customController.text.trim());
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Enter a duration of at least 1 minute.'),
          ),
        );
      return;
    }
    if (parsed > 24 * 60) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Choose 24 hours or less.')),
        );
      return;
    }
    widget.playerState.setSleepTimer(parsed);
    FocusScope.of(context).unfocus();
  }

  String _remainingLabel(Duration remaining) {
    final totalSeconds = remaining.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m '
          '${seconds.toString().padLeft(2, '0')}s';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Sleep Timer', style: AppTextStyles.headlineMedium),
      content: ListenableBuilder(
        listenable: widget.playerState,
        builder: (context, _) {
          final player = widget.playerState;
          final remaining = player.sleepTimerRemaining;

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pause playback after:', style: AppTextStyles.bodyMedium),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    ...SleepTimerDialog.presets.map((mins) {
                      final isSelected = player.sleepTimerMinutes == mins;
                      return ChoiceChip(
                        label: Text('$mins min'),
                        selected: isSelected,
                        onSelected: (_) =>
                            player.setSleepTimer(isSelected ? null : mins),
                        selectedColor: AppColors.accentViolet.withValues(
                          alpha: 0.3,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.accentVioletLight
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }),
                    ChoiceChip(
                      label: const Text('Off'),
                      selected: !player.hasActiveSleepTimer,
                      onSelected: (_) => player.setSleepTimer(null),
                      selectedColor: AppColors.accentViolet.withValues(
                        alpha: 0.3,
                      ),
                      labelStyle: TextStyle(
                        color: !player.hasActiveSleepTimer
                            ? AppColors.accentVioletLight
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Custom minutes', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          hintText: 'e.g. 20',
                          isDense: true,
                        ),
                        onSubmitted: (_) => _applyCustom(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    TextButton(
                      onPressed: _applyCustom,
                      child: const Text('Set'),
                    ),
                  ],
                ),
                if (remaining != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_rounded,
                        color: AppColors.accentViolet,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Pausing in ${_remainingLabel(remaining)}',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.accentVioletLight,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => player.setSleepTimer(null),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Text(
                      'No sleep timer active.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
