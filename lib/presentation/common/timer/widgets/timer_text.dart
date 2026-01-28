import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../viewmodel/tracking_notifier.dart';

/// A widget that displays the timer text.
class TimerText extends HookConsumerWidget {
  final int? timeInMs;

  const TimerText({super.key, this.timeInMs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingState = ref.watch(trackingNotifierProvider);
    final trackingNotifier = ref.watch(trackingNotifierProvider.notifier);

    const TextStyle timerTextStyle =
        TextStyle(fontSize: 60.0, fontFamily: "Open Sans");

    return Text(
      timeInMs != null
          ? trackingNotifier
              .formatDuration((timeInMs! / 1000).floor())
          : trackingNotifier.formatDuration(trackingState.durationSeconds),
      style: timerTextStyle,
    );
  }
}
