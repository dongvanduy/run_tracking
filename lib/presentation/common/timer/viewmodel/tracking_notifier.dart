import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';


/// Provides a global tracking notifier that keeps tracking state across tabs.
final trackingNotifierProvider =
    NotifierProvider<TrackingNotifier, TrackingState>(TrackingNotifier.new);

/// Represents the tracking state for timer and GPS data.
class TrackingState {
  /// Whether tracking is currently active.
  final bool isTracking;

  /// Elapsed duration in seconds.
  final int durationSeconds;

  /// Total distance in meters.
  final double distanceMeters;

  /// All collected GPS points in order.
  final List<Position> pathPoints;

  /// The most recent GPS position.
  final Position? currentPosition;

  /// Creates a tracking state instance.
  const TrackingState({
    required this.isTracking,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.pathPoints,
    required this.currentPosition,
  });

  /// Creates the initial tracking state.
  factory TrackingState.initial() {
    return const TrackingState(
      isTracking: false,
      durationSeconds: 0,
      distanceMeters: 0,
      pathPoints: [],
      currentPosition: null,
    );
  }

  /// Returns a copy of the current state with updated fields.
  TrackingState copyWith({
    bool? isTracking,
    int? durationSeconds,
    double? distanceMeters,
    List<Position>? pathPoints,
    Position? currentPosition,
  }) {
    return TrackingState(
      isTracking: isTracking ?? this.isTracking,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      pathPoints: pathPoints ?? this.pathPoints,
      currentPosition: currentPosition ?? this.currentPosition,
    );
  }
}

/// Manages the tracking timer and GPS stream with Riverpod Notifier.
class TrackingNotifier extends Notifier<TrackingState> {
  Timer? _timer;
  StreamSubscription<Position>? _positionSubscription;
  DateTime? _startTime;

  @override
  TrackingState build() {
    return TrackingState.initial();
  }

  /// The moment tracking started, if available.
  DateTime? get startTime => _startTime;

  /// Whether a tracking session has already started.
  bool get hasTrackingStarted => _startTime != null;

  /// Starts tracking: requests permissions, starts GPS stream, and timer.
  Future<void> startTracking() async {
    if (state.isTracking) {
      return;
    }

    final permissionGranted = await _ensureLocationPermission();
    if (!permissionGranted) {
      return;
    }

    _startTime ??= DateTime.now();
    _startLocationStream();
    state = state.copyWith(isTracking: true);
    _startTimer();
  }

  /// Pauses tracking without resetting values.
  void pauseTracking() {
    if (!hasTrackingStarted) {
      return;
    }
    state = state.copyWith(isTracking: false);
    _timer?.cancel();
    _timer = null;
    _positionSubscription?.pause();
  }

  /// Resumes tracking after a pause.
  Future<void> resumeTracking() async {
    if (state.isTracking) {
      return;
    }

    if (_positionSubscription == null) {
      await startTracking();
      return;
    }

    state = state.copyWith(isTracking: true);
    _positionSubscription?.resume();
    _startTimer();
  }

  /// Stops tracking and releases resources, keeping collected data intact.
  Future<void> stopTracking() async {
    state = state.copyWith(isTracking: false);
    _timer?.cancel();
    _timer = null;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Resets tracking data and cancels active services.
  Future<void> reset() async {
    await stopTracking();
    _startTime = null;
    state = TrackingState.initial();
  }

  /// Formats a duration in seconds as mm:ss or hh:mm:ss.
  String formatDuration([int? durationSeconds]) {
    final totalSeconds = durationSeconds ?? state.durationSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final hoursFormatted = hours.toString().padLeft(2, '0');
    final minutesFormatted = minutes.toString().padLeft(2, '0');
    final secondsFormatted = seconds.toString().padLeft(2, '0');

    return hours > 0
        ? '$hoursFormatted:$minutesFormatted:$secondsFormatted'
        : '$minutesFormatted:$secondsFormatted';
  }

  /// Starts the periodic timer that increments the duration every second.
  void _startTimer() {
    if (_timer != null) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isTracking) {
        return;
      }
      state = state.copyWith(durationSeconds: state.durationSeconds + 1);
    });
  }

  /// Ensures the app has location permission.
  Future<bool> _ensureLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Starts the location stream and tracks distance updates.
  void _startLocationStream() {
    if (_positionSubscription != null) {
      return;
    }

    _positionSubscription =
        Geolocator.getPositionStream().listen((Position position) {
      final points = List<Position>.from(state.pathPoints);
      double updatedDistance = state.distanceMeters;

      if (points.isNotEmpty) {
        final last = points.last;
        updatedDistance += Geolocator.distanceBetween(
          last.latitude,
          last.longitude,
          position.latitude,
          position.longitude,
        );
      }

      points.add(position);
      state = state.copyWith(
        pathPoints: points,
        currentPosition: position,
        distanceMeters: updatedDistance,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}
