import 'dart:io';
import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/utils/storage_utils.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../model/request/edit_password_request.dart';
import '../model/request/edit_profile_request.dart';
import '../model/request/login_request.dart';
import '../model/request/registration_request.dart';
import '../model/request/send_new_password_request.dart';
import '../model/response/login_response.dart';
import '../model/response/user_response.dart';
import '../services/isar_service.dart';
import '../services/local_auth_storage.dart';

/// Provider for the UserRepository implementation.
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(
    ref.read(isarServiceProvider),
    ref.read(localAuthStorageProvider),
  );
});

/// Implementation of the UserRepository.
class UserRepositoryImpl extends UserRepository {
  UserRepositoryImpl(this._isarService, this._authStorage);

  final IsarService _isarService;
  final LocalAuthStorage _authStorage;

  @override
  Future<int> register(RegistrationRequest request) async {
    final isar = await _isarService.getInstance();
    final existing = await isar.collection<UserResponse>()
        .filter()
        .usernameEqualTo(request.username)
        .findFirst();
    if (existing != null) {
      throw Exception('Username already exists.');
    }

    final user = UserResponse(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: request.username,
      firstname: request.firstname,
      lastname: request.lastname,
    );

    await isar.writeTxn(() async {
      await isar.collection<UserResponse>().put(user);
    });

    await _authStorage.setPassword(user.id, request.password);
    return 1;
  }

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    final isar = await _isarService.getInstance();
    final user = await isar.collection<UserResponse>()
        .filter()
        .usernameEqualTo(request.username)
        .findFirst();
    if (user == null) {
      throw Exception('No local profile found for this username.');
    }

    final storedPassword = await _authStorage.getPassword(user.id);
    if (storedPassword != request.password) {
      throw Exception('Invalid credentials.');
    }

    final response = LoginResponse(
      refreshToken: '',
      token: '',
      user: user,
      message: 'Local login successful.',
    );
    await StorageUtils.setLoggedIn(true);
    await StorageUtils.setUser(user);
    return response;
  }

  @override
  Future<void> logout() async {
    await StorageUtils.removeJwt();
    await StorageUtils.removeRefreshToken();
    await StorageUtils.removeLoggedIn();
    await StorageUtils.removeUser();
  }

  @override
  Future<void> delete() async {
    final isar = await _isarService.getInstance();
    final user = await StorageUtils.getUser();
    if (user == null) {
      return;
    }
    final response = await isar.collection<UserResponse>()
        .filter()
        .idEqualTo(user.id)
        .findFirst();
    if (response != null) {
      await isar.writeTxn(() async {
        await isar.collection<UserResponse>().delete(response.isarId);
      });
    }
    await _authStorage.removePassword(user.id);
    await StorageUtils.removeLoggedIn();
    await StorageUtils.removeUser();
  }

  @override
  Future<void> sendNewPasswordByMail(SendNewPasswordRequest request) async {
    throw Exception('Password recovery is not available offline.');
  }

  @override
  Future<void> editPassword(EditPasswordRequest request) async {
    final user = await StorageUtils.getUser();
    if (user == null) {
      throw Exception('No logged-in user found.');
    }
    await _authStorage.setPassword(user.id, request.password);
  }

  @override
  Future<void> editProfile(EditProfileRequest request) async {
    final isar = await _isarService.getInstance();
    final currentUser = await StorageUtils.getUser();
    if (currentUser == null) {
      throw Exception('No logged-in user found.');
    }
    final response = await isar.collection<UserResponse>()
        .filter()
        .idEqualTo(currentUser.id)
        .findFirst();
    if (response == null) {
      throw Exception('Unable to locate local profile.');
    }
    response.firstname = request.firstname;
    response.lastname = request.lastname;
    await isar.writeTxn(() async {
      await isar.collection<UserResponse>().put(response);
    });
    await StorageUtils.setUser(response);
  }

  @override
  Future<List<User>> search(String text) async {
    final isar = await _isarService.getInstance();
    final responses = await isar.collection<UserResponse>()
        .filter()
        .usernameContains(text, caseSensitive: false)
        .findAll();
    return responses.map((response) => response.toEntity()).toList();
  }

  @override
  Future<Uint8List?> downloadProfilePicture(String id) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/profile_$id.jpg');
    if (!file.existsSync()) {
      return null;
    }
    return file.readAsBytes();
  }

  @override
  Future<void> uploadProfilePicture(Uint8List file) async {
    final user = await StorageUtils.getUser();
    if (user == null) {
      throw Exception('No logged-in user found.');
    }
    final directory = await getApplicationDocumentsDirectory();
    final profileFile = File('${directory.path}/profile_${user.id}.jpg');
    await profileFile.writeAsBytes(file, flush: true);
  }
}
