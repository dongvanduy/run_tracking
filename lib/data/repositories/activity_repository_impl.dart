import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';

import '../../core/utils/storage_utils.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_comment.dart';
import '../../domain/entities/page.dart';
import '../../domain/repositories/activity_repository.dart';
import '../model/request/activity_request.dart';
import '../model/response/activity_comment_response.dart';
import '../model/response/activity_response.dart';
import '../model/response/location_response.dart';
import '../model/response/user_response.dart';
import '../services/isar_service.dart';

/// Provider for the ActivityRepository implementation.
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepositoryImpl(ref.read(isarServiceProvider));
});

/// Implementation of the ActivityRepository.
class ActivityRepositoryImpl extends ActivityRepository {
  ActivityRepositoryImpl(this._isarService);

  static const int _activitiesPageSize = 20;
  static const int _communityPageSize = 10;

  final IsarService _isarService;

  Future<List<ActivityResponse>> _loadActivities(
    QueryBuilder<ActivityResponse, ActivityResponse, QAfterSortBy> query,
    int pageNumber,
    int pageSize,
  ) async {
    final activities = await query
        .offset(pageNumber * pageSize)
        .limit(pageSize)
        .findAll();
    for (final activity in activities) {
      await activity.user.load();
      await activity.locations.load();
    }
    return activities;
  }

  @override
  Future<EntityPage<Activity>> getActivities({int pageNumber = 0}) async {
    final isar = await _isarService.getInstance();
    final total = await isar.activityResponses.count();
    final responses = await _loadActivities(
      isar.activityResponses.where().sortByStartDatetimeDesc(),
      pageNumber,
      _activitiesPageSize,
    );
    final activities = responses.map((response) => response.toEntity()).toList();
    return EntityPage(list: activities, total: total);
  }

  @override
  Future<EntityPage<Activity>> getMyAndMyFriendsActivities(
      {int pageNumber = 0}) async {
    final isar = await _isarService.getInstance();
    final total = await isar.activityResponses.count();
    final responses = await _loadActivities(
      isar.activityResponses.where().sortByStartDatetimeDesc(),
      pageNumber,
      _communityPageSize,
    );
    final activities = responses.map((response) => response.toEntity()).toList();
    return EntityPage(list: activities, total: total);
  }

  @override
  Future<EntityPage<Activity>> getUserActivities(String userId,
      {int pageNumber = 0}) async {
    final isar = await _isarService.getInstance();
    final total = await isar.activityResponses
        .filter()
        .userIdEqualTo(userId)
        .count();
    final responses = await _loadActivities(
      isar.activityResponses
          .filter()
          .userIdEqualTo(userId)
          .sortByStartDatetimeDesc(),
      pageNumber,
      _activitiesPageSize,
    );
    final activities = responses.map((response) => response.toEntity()).toList();
    return EntityPage(list: activities, total: total);
  }

  @override
  Future<Activity> getActivityById({required String id}) async {
    final isar = await _isarService.getInstance();
    final activity = await isar.activityResponses.filter().idEqualTo(id).findFirst();
    if (activity == null) {
      throw Exception('Activity not found.');
    }
    await activity.user.load();
    await activity.locations.load();
    return activity.toEntity();
  }

  @override
  Future<String?> removeActivity({required String id}) async {
    final isar = await _isarService.getInstance();
    final activity = await isar.activityResponses.filter().idEqualTo(id).findFirst();
    if (activity == null) {
      return null;
    }

    await activity.locations.load();
    await isar.writeTxn(() async {
      await isar.activityResponses.delete(activity.isarId);
      for (final location in activity.locations) {
        await isar.locationResponses.delete(location.isarId);
      }
    });
    return id;
  }

  @override
  Future<Activity?> addActivity(ActivityRequest request) async {
    final isar = await _isarService.getInstance();
    final currentUser = await StorageUtils.getUser();
    if (currentUser == null) {
      throw Exception('No local profile found.');
    }

    final durationMs = request.endDatetime
        .difference(request.startDatetime)
        .inMilliseconds;
    final durationHours = durationMs / 3600000;
    final speed = durationHours > 0
        ? request.distance / durationHours
        : 0.0;

    final activity = ActivityResponse(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUser.id,
      type: request.type,
      startDatetime: request.startDatetime,
      endDatetime: request.endDatetime,
      distance: request.distance,
      speed: speed,
      time: durationMs.toDouble(),
      likesCount: 0,
      hasCurrentUserLiked: false,
      comments: [],
    );

    final userResponse = UserResponse(
      id: currentUser.id,
      username: currentUser.username,
      firstname: currentUser.firstname,
      lastname: currentUser.lastname,
    );

    final locations = request.locations.map((location) {
      return LocationResponse(
        id: location.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        datetime: location.datetime,
        latitude: location.latitude,
        longitude: location.longitude,
      );
    }).toList();

    await isar.writeTxn(() async {
      await isar.userResponses.put(userResponse);
      activity.user.value = userResponse;
      await isar.locationResponses.putAll(locations);
      activity.locations.addAll(locations);
      await isar.activityResponses.put(activity);
      await activity.user.save();
      await activity.locations.save();
    });

    return activity.toEntity();
  }

  @override
  Future<Activity> editActivity(ActivityRequest request) async {
    final isar = await _isarService.getInstance();
    if (request.id == null) {
      throw Exception('Activity id is required.');
    }
    final activity =
        await isar.activityResponses.filter().idEqualTo(request.id!).findFirst();
    if (activity == null) {
      throw Exception('Activity not found.');
    }

    await activity.locations.load();
    await isar.writeTxn(() async {
      for (final location in activity.locations) {
        await isar.locationResponses.delete(location.isarId);
      }
      activity.locations.clear();

      final locations = request.locations.map((location) {
        return LocationResponse(
          id: location.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
          datetime: location.datetime,
          latitude: location.latitude,
          longitude: location.longitude,
        );
      }).toList();

      await isar.locationResponses.putAll(locations);
      activity.locations.addAll(locations);

      activity.type = request.type;
      activity.startDatetime = request.startDatetime;
      activity.endDatetime = request.endDatetime;
      activity.distance = request.distance;
      final durationMs = request.endDatetime
          .difference(request.startDatetime)
          .inMilliseconds;
      final durationHours = durationMs / 3600000;
      activity.speed = durationHours > 0
          ? request.distance / durationHours
          : 0.0;
      activity.time = durationMs.toDouble();

      await isar.activityResponses.put(activity);
      await activity.locations.save();
    });

    await activity.user.load();
    await activity.locations.load();
    return activity.toEntity();
  }

  @override
  Future<void> like(String id) async {
    final isar = await _isarService.getInstance();
    final activity = await isar.activityResponses.filter().idEqualTo(id).findFirst();
    if (activity == null) {
      return;
    }
    activity.likesCount += 1;
    activity.hasCurrentUserLiked = true;
    await isar.writeTxn(() async {
      await isar.activityResponses.put(activity);
    });
  }

  @override
  Future<void> dislike(String id) async {
    final isar = await _isarService.getInstance();
    final activity = await isar.activityResponses.filter().idEqualTo(id).findFirst();
    if (activity == null) {
      return;
    }
    activity.likesCount = (activity.likesCount - 1).clamp(0, double.infinity);
    activity.hasCurrentUserLiked = false;
    await isar.writeTxn(() async {
      await isar.activityResponses.put(activity);
    });
  }

  @override
  Future<ActivityComment?> createComment(
      String activityId, String comment) async {
    final isar = await _isarService.getInstance();
    final activity = await isar.activityResponses
        .filter()
        .idEqualTo(activityId)
        .findFirst();
    if (activity == null) {
      throw Exception('Activity not found.');
    }

    final user = await StorageUtils.getUser();
    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    final response = ActivityCommentResponse(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      userId: user.id,
      username: user.username,
      firstname: user.firstname,
      lastname: user.lastname,
      content: comment,
    );

    activity.comments.add(response);
    await isar.writeTxn(() async {
      await isar.activityResponses.put(activity);
    });

    return response.toEntity();
  }

  @override
  Future<ActivityComment> editComment(String id, String comment) async {
    final isar = await _isarService.getInstance();
    final activities = await isar.activityResponses.where().findAll();
    ActivityCommentResponse? updated;

    await isar.writeTxn(() async {
      for (final activity in activities) {
        final index =
            activity.comments.indexWhere((response) => response.id == id);
        if (index != -1) {
          final existing = activity.comments[index];
          existing.content = comment;
          activity.comments[index] = existing;
          updated = existing;
          await isar.activityResponses.put(activity);
          break;
        }
      }
    });

    if (updated == null) {
      throw Exception('Comment not found.');
    }

    return updated!.toEntity();
  }

  @override
  Future<String?> removeComment({required String id}) async {
    final isar = await _isarService.getInstance();
    final activities = await isar.activityResponses.where().findAll();
    bool removed = false;

    await isar.writeTxn(() async {
      for (final activity in activities) {
        final initialLength = activity.comments.length;
        activity.comments.removeWhere((comment) => comment.id == id);
        if (activity.comments.length < initialLength) {
          removed = true;
          await isar.activityResponses.put(activity);
          break;
        }
      }
    });

    return removed ? id : null;
  }
}
