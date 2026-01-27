import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/entities/enum/friend_request_status.dart';
import '../../domain/entities/friend_request.dart';
import '../../domain/entities/page.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/friend_request_repository.dart';

/// Provider for the FriendRequestRepository implementation.
final friendRequestRepositoryProvider =
    Provider<FriendRequestRepository>((ref) => FriendRequestRepositoryImpl());

/// Implementation of the FriendRequestRepository.
class FriendRequestRepositoryImpl extends FriendRequestRepository {
  FriendRequestRepositoryImpl();

  @override
  Future<EntityPage<User>> getPendingRequestUsers({int pageNumber = 0}) async {
    return const EntityPage(list: [], total: 0);
  }

  @override
  Future<FriendRequestStatus?> getStatus(String userId) async {
    return FriendRequestStatus.noDisplay;
  }

  @override
  Future<int> sendRequest(String userId) async {
    return 0;
  }

  @override
  Future<FriendRequest> accept(String userId) async {
    return const FriendRequest(status: FriendRequestStatus.accepted);
  }

  @override
  Future<FriendRequest> reject(String userId) async {
    return const FriendRequest(status: FriendRequestStatus.rejected);
  }

  @override
  Future<FriendRequest> cancel(String userId) async {
    return const FriendRequest(status: FriendRequestStatus.canceled);
  }
}
