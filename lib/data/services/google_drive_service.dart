import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/entities/enum/activity_type.dart';
import '../model/response/activity_comment_response.dart';
import '../model/response/activity_response.dart';
import '../model/response/location_response.dart';
import '../model/response/user_response.dart';
import 'isar_service.dart';

final googleDriveServiceProvider = Provider<GoogleDriveService>(
  (ref) => GoogleDriveService(ref.read(isarServiceProvider)),
);

/// Service responsible for Google Drive backup and restore operations.
class GoogleDriveService {
  GoogleDriveService(this._isarService);

  static const String backupFileName = 'run_tracking_backup.json';

  final IsarService _isarService;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  Future<drive.DriveApi> _getDriveApi() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Google sign-in cancelled.');
    }
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      throw Exception('Unable to authenticate with Google Drive.');
    }
    return drive.DriveApi(client);
  }

  Future<Map<String, dynamic>> _buildBackupPayload() async {
    final isar = await _isarService.getInstance();
    final activities = await isar.collection<ActivityResponse>().where().findAll();
    for (final activity in activities) {
      await activity.user.load();
      await activity.locations.load();
    }
    final users = await isar.collection<UserResponse>().where().findAll();
    final locations = await isar.collection<LocationResponse>().where().findAll();

    return {
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'users': users.map((user) => user.toJson()).toList(),
      'locations': locations.map((location) => location.toJson()).toList(),
      'activities': activities.map((activity) => activity.toJson()).toList(),
    };
  }

  Future<void> backupDatabase() async {
    try {
      final driveApi = await _getDriveApi();
      final payload = await _buildBackupPayload();
      final bytes = utf8.encode(jsonEncode(payload));

      final fileMetadata = drive.File()
        ..name = backupFileName
        ..parents = ['appDataFolder'];

      final existing = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$backupFileName'",
        $fields: 'files(id, name)',
      );

      final media = drive.Media(Stream.value(bytes), bytes.length);

      if (existing.files != null && existing.files!.isNotEmpty) {
        final fileId = existing.files!.first.id!;
        await driveApi.files.update(
          fileMetadata,
          fileId,
          uploadMedia: media,
        );
      } else {
        await driveApi.files.create(
          fileMetadata,
          uploadMedia: media,
        );
      }
    } catch (error) {
      throw Exception('Failed to back up data: $error');
    }
  }

  Future<void> restoreDatabase() async {
    try {
      final driveApi = await _getDriveApi();
      final files = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$backupFileName'",
        $fields: 'files(id, name)',
      );

      if (files.files == null || files.files!.isEmpty) {
        throw Exception('No backup file found in Google Drive.');
      }

      final fileId = files.files!.first.id!;
      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = await _collectMedia(media);
      final jsonData = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

      await _restoreFromPayload(jsonData);
    } catch (error) {
      throw Exception('Failed to restore data: $error');
    }
  }

  Future<Uint8List> _collectMedia(drive.Media media) async {
    final chunks = <int>[];
    await for (final chunk in media.stream) {
      chunks.addAll(chunk);
    }
    return Uint8List.fromList(chunks);
  }

  Future<void> _restoreFromPayload(Map<String, dynamic> payload) async {
    final isar = await _isarService.getInstance();
    final usersJson = List<Map<String, dynamic>>.from(payload['users'] ?? []);
    final locationsJson =
        List<Map<String, dynamic>>.from(payload['locations'] ?? []);
    final activitiesJson =
        List<Map<String, dynamic>>.from(payload['activities'] ?? []);

    await isar.writeTxn(() async {
      await isar.collection<ActivityResponse>().clear();
      await isar.collection<LocationResponse>().clear();
      await isar.collection<UserResponse>().clear();

      final users = usersJson.map(UserResponse.fromMap).toList();
      await isar.collection<UserResponse>().putAll(users);

      final locations = locationsJson.map(LocationResponse.fromMap).toList();
      await isar.collection<LocationResponse>().putAll(locations);

      final userById = {for (final user in users) user.id: user};
      final locationById = {
        for (final location in locations) location.id: location
      };

      for (final activityMap in activitiesJson) {
        final activityTypeString =
            activityMap['type']?.toString().toLowerCase();
        final activityType = ActivityType.values.firstWhere(
          (type) => type.name.toLowerCase() == activityTypeString,
          orElse: () => ActivityType.running,
        );
        final userJson = activityMap['user'] as Map<String, dynamic>? ?? {};
        final activity = ActivityResponse(
          id: activityMap['id'].toString(),
          userId: activityMap['userId']?.toString() ??
              userJson['id']?.toString() ??
              '',
          type: activityType,
          startDatetime: DateTime.parse(activityMap['startDatetime']),
          endDatetime: DateTime.parse(activityMap['endDatetime']),
          distance: (activityMap['distance'] as num).toDouble(),
          speed: (activityMap['speed'] as num).toDouble(),
          time: (activityMap['time'] as num).toDouble(),
          likesCount: (activityMap['likesCount'] as num).toDouble(),
          hasCurrentUserLiked: activityMap['hasCurrentUserLiked'] ?? false,
          comments: List<Map<String, dynamic>>.from(activityMap['comments'] ?? [])
              .map(ActivityCommentResponse.fromMap)
              .toList(),
        );

        final user = userById[activity.userId] ??
            UserResponse(
              id: activity.userId,
              username: userJson['username']?.toString() ?? '',
              firstname: userJson['firstname']?.toString(),
              lastname: userJson['lastname']?.toString(),
            );
        userById[activity.userId] = user;
        await isar.collection<UserResponse>().put(user);
        activity.user.value = user;

        for (final locationMap in
            List<Map<String, dynamic>>.from(activityMap['locations'] ?? [])) {
          final locationId = locationMap['id'].toString();
          final location = locationById[locationId] ??
              LocationResponse.fromMap(locationMap);
          locationById[locationId] = location;
          await isar.collection<LocationResponse>().put(location);
          activity.locations.add(location);
        }

        await isar.collection<ActivityResponse>().put(activity);
        await activity.user.save();
        await activity.locations.save();
      }
    });
  }
}
