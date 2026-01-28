import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../viewmodel/tracking_notifier.dart';
import 'timer_text.dart';

/// A widget that displays the timer text with a fixed size.
class TimerTextSized extends HookConsumerWidget {
  const TimerTextSized({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(trackingNotifierProvider);

    return const Column(
      children: <Widget>[
        SizedBox(
          height: 125,
          child: Center(
            child: TimerText(),
          ),
        )
      ],
    );
  }
}
