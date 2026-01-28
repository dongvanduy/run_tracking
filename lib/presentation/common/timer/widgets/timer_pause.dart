import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/utils/color_utils.dart';
import '../viewmodel/tracking_notifier.dart';

/// A floating action button used to pause or resume the timer.
class TimerPause extends HookConsumerWidget {
  const TimerPause({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingState = ref.watch(trackingNotifierProvider);
    final trackingNotifier = ref.watch(trackingNotifierProvider.notifier);

    if (trackingNotifier.hasTrackingStarted) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: child,
          );
        },
        child: FloatingActionButton(
          heroTag: 'pause_resume_button',
          backgroundColor: ColorUtils.main,
          key: ValueKey<bool>(trackingState.isTracking),
          tooltip: trackingState.isTracking ? 'Pause' : 'Resume',
          child: Icon(
            trackingState.isTracking ? Icons.pause : Icons.play_arrow,
            color: ColorUtils.white,
          ),
          onPressed: () async {
            if (trackingState.isTracking) {
              trackingNotifier.pauseTracking();
            } else {
              await trackingNotifier.resumeTracking();
            }
          },
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
