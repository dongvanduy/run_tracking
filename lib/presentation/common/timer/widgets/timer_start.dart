import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/utils/color_utils.dart';
import '../../../../../main.dart';
import '../viewmodel/tracking_notifier.dart';

/// A widget that displays the timer start button.
class TimerStart extends HookConsumerWidget {
  const TimerStart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingState = ref.watch(trackingNotifierProvider);
    final trackingNotifier = ref.watch(trackingNotifierProvider.notifier);
    final hasTrackingStarted =
        trackingNotifier.hasTrackingStarted || trackingState.isTracking;

    return FloatingActionButton(
      heroTag: 'start_button',
      backgroundColor: hasTrackingStarted
          ? ColorUtils.errorDarker
          : ColorUtils.main,
      elevation: 4.0,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: Icon(
          hasTrackingStarted ? Icons.stop : Icons.play_arrow,
          key: ValueKey<bool>(hasTrackingStarted),
          color: ColorUtils.white,
        ),
      ),
      onPressed: () async {
        if (hasTrackingStarted) {
          await trackingNotifier.stopTracking();
          navigatorKey.currentState?.pushNamed('/sumup');
        } else {
          await trackingNotifier.startTracking();
        }
      },
    );
  }
}
