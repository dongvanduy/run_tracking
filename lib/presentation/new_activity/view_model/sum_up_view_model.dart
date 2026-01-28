import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/model/request/activity_request.dart';
import '../../../data/model/request/location_request.dart';
import '../../../data/repositories/activity_repository_impl.dart';
import '../../../domain/entities/activity.dart';
import '../../../domain/entities/enum/activity_type.dart';
import '../../../domain/entities/location.dart';
import '../../../domain/entities/user.dart';
import '../../../main.dart';
import '../../common/core/utils/activity_utils.dart';
import '../../common/timer/viewmodel/tracking_notifier.dart';
import 'state/sum_up_state.dart';

/// Provides the instance of [SumUpViewModel].
final sumUpViewModel = Provider.autoDispose((ref) {
  return SumUpViewModel(ref);
});

/// Provides the state management for the SumUpScreen.
final sumUpViewModelProvider =
    StateNotifierProvider.autoDispose<SumUpViewModel, SumUpState>(
  (ref) => SumUpViewModel(ref),
);

/// Represents the view model for the SumUpScreen.
class SumUpViewModel extends StateNotifier<SumUpState> {
  late Ref ref;

  /// Creates a new instance of [SumUpViewModel] with the given [ref].
  SumUpViewModel(this.ref) : super(SumUpState.initial());

  /// Sets the selected [type] of the activity.
  void setType(ActivityType type) {
    state = state.copyWith(type: type);
  }

  /// Saves the activity.
  void save() async {
    state = state.copyWith(isSaving: true);

    final trackingState = ref.read(trackingNotifierProvider);
    final trackingNotifier = ref.read(trackingNotifierProvider.notifier);
    final startDatetime = trackingNotifier.startTime ?? DateTime.now();
    final endDatetime = startDatetime.add(Duration(
      seconds: trackingState.durationSeconds,
    ));

    final locations = trackingState.pathPoints;

    ref
        .read(activityRepositoryProvider)
        .addActivity(ActivityRequest(
          type: state.type,
          startDatetime: startDatetime,
          endDatetime: endDatetime,
          distance: trackingState.distanceMeters / 1000,
          locations: locations
              .map(
                (position) => LocationRequest(
                  datetime: position.timestamp ?? DateTime.now(),
                  latitude: position.latitude,
                  longitude: position.longitude,
                ),
              )
              .toList(),
        ))
        .then((value) async {
      if (value != null) {
        ActivityUtils.updateActivity(ref, value, ActivityUpdateActionEnum.add);
      }
      await ref.read(trackingNotifierProvider.notifier).reset();

      state = state.copyWith(isSaving: false);
      navigatorKey.currentState?.pop();
    });
  }

  Activity getActivity() {
    final trackingState = ref.read(trackingNotifierProvider);
    final trackingNotifier = ref.read(trackingNotifierProvider.notifier);
    final startDatetime = trackingNotifier.startTime ?? DateTime.now();
    final endDatetime = startDatetime.add(Duration(
      seconds: trackingState.durationSeconds,
    ));
    final locations = trackingState.pathPoints;
    final distanceKm = trackingState.distanceMeters / 1000;
    double speed = 0;
    if (trackingState.durationSeconds > 0) {
      speed = distanceKm /
          (trackingState.durationSeconds / Duration.secondsPerHour);
    }

    return Activity(
        id: '',
        type: state.type,
        startDatetime: startDatetime,
        endDatetime: endDatetime,
        distance: distanceKm,
        speed: speed,
        time: trackingState.durationSeconds * 1000,
        likesCount: 0,
        hasCurrentUserLiked: false,
        locations: locations
            .map((l) => Location(
                id: '',
                datetime: l.timestamp ?? DateTime.now(),
                latitude: l.latitude,
                longitude: l.longitude))
            .toList(),
        user: const User(id: '', username: '', firstname: '', lastname: ''),
        comments: const []);
  }
}
