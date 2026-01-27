import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';

import '../../../domain/entities/activity.dart';
import '../../../domain/entities/activity_comment.dart';
import '../../../domain/entities/enum/activity_type.dart';
import '../../../domain/entities/location.dart';
import '../../../domain/entities/user.dart';
import 'activity_comment_response.dart';
import 'location_response.dart';
import 'user_response.dart';

/// Represents a response object for an activity.
part 'activity_response.g.dart';

@collection
class ActivityResponse extends Equatable {
  /// Isar database identifier.
  Id isarId = Isar.autoIncrement;

  /// The ID of the activity.
  late String id;

  /// The user id for queries.
  late String userId;

  /// The type of the activity.
  @enumerated
  late ActivityType type;

  /// The start datetime of the activity.
  late DateTime startDatetime;

  /// The end datetime of the activity.
  late DateTime endDatetime;

  /// The distance covered in the activity.
  late double distance;

  /// The average speed in the activity.
  late double speed;

  /// The total time of the activity.
  late double time;

  /// The list of locations associated with the activity.
  final IsarLinks<LocationResponse> locations = IsarLinks<LocationResponse>();

  /// The user concerned by the activity
  final IsarLink<UserResponse> user = IsarLink<UserResponse>();

  /// The count of likes on the activity
  late double likesCount;

  /// has current user liked ?
  late bool hasCurrentUserLiked;

  /// The list of comments
  late List<ActivityCommentResponse> comments;

  /// Constructs an ActivityResponse object with the given parameters.
  ActivityResponse({
    required this.id,
    required this.userId,
    required this.type,
    required this.startDatetime,
    required this.endDatetime,
    required this.distance,
    required this.speed,
    required this.time,
    required this.likesCount,
    required this.hasCurrentUserLiked,
    List<ActivityCommentResponse>? comments,
  }) : comments = comments ?? [];

  @override
  List<Object?> get props => [
        id,
        type,
        startDatetime,
        endDatetime,
        distance,
        speed,
        time,
        ...locations,
        user.value,
        likesCount,
        hasCurrentUserLiked,
        ...comments
      ];

  /// Creates an ActivityResponse object from a JSON map.
  factory ActivityResponse.fromMap(Map<String, dynamic> map) {
    final activityTypeString = map['type']?.toString().toLowerCase();
    final activityType = ActivityType.values.firstWhere(
      (type) => type.name.toLowerCase() == activityTypeString,
      orElse: () => ActivityType.running,
    );

    final user = UserResponse.fromMap(map['user']);
    final locations = (map['locations'] as List<dynamic>)
        .map<LocationResponse>((item) => LocationResponse.fromMap(item))
        .toList();
    final commentsList = (map['comments'] as List<dynamic>? ?? const []);
    final activity = ActivityResponse(
      id: map['id'].toString(),
      userId: user.id,
      type: activityType,
      startDatetime: DateTime.parse(map['startDatetime']),
      endDatetime: DateTime.parse(map['endDatetime']),
      distance: map['distance'].toDouble(),
      speed: map['speed'] is String
          ? double.parse(map['speed'])
          : map['speed'].toDouble(),
      time: map['time'].toDouble(),
      likesCount: map['likesCount'].toDouble(),
      hasCurrentUserLiked: map['hasCurrentUserLiked'],
      comments: commentsList
          .map<ActivityCommentResponse>(
              (item) => ActivityCommentResponse.fromMap(item))
          .toList(),
    );
    activity.user.value = user;
    activity.locations.addAll(locations);
    return activity;
  }

  /// Converts the ActivityResponse object to an Activity entity.
  Activity toEntity() {
    final activityLocations = locations.map<Location>((location) {
      return Location(
        id: location.id,
        datetime: location.datetime,
        latitude: location.latitude,
        longitude: location.longitude,
      );
    }).toList()
      ..sort((a, b) => a.datetime.compareTo(b.datetime));

    final activityComments =
        comments.map<ActivityComment>((comment) => comment.toEntity()).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Activity(
        id: id,
        type: type,
        startDatetime: startDatetime,
        endDatetime: endDatetime,
        distance: distance,
        speed: speed,
        time: time,
        locations: activityLocations,
        likesCount: likesCount,
        hasCurrentUserLiked: hasCurrentUserLiked,
        user: User(
            id: user.value?.id ?? userId,
            username: user.value?.username ?? '',
            firstname: user.value?.firstname,
            lastname: user.value?.lastname),
        comments: activityComments);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'startDatetime': startDatetime.toIso8601String(),
      'endDatetime': endDatetime.toIso8601String(),
      'distance': distance,
      'speed': speed,
      'time': time,
      'likesCount': likesCount,
      'hasCurrentUserLiked': hasCurrentUserLiked,
      'user': user.value?.toJson(),
      'locations': locations.map((location) => location.toJson()).toList(),
      'comments': comments.map((comment) => comment.toJson()).toList(),
    };
  }
}
