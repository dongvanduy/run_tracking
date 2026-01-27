import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';

import '../../../domain/entities/activity_comment.dart';
import '../../../domain/entities/user.dart';

/// Represents a response object for an activity comment.
part 'activity_comment_response.g.dart';

@embedded
class ActivityCommentResponse extends Equatable {
  /// The ID of the comment.
  late String id;

  /// The datetime of the comment
  late DateTime createdAt;

  /// The user id
  late String userId;

  /// The username
  late String username;

  /// The firstname
  String? firstname;

  /// The lastname
  String? lastname;

  /// The comment content
  late String content;

  /// Constructs an ActivityCommentResponse object with the given parameters.
  ActivityCommentResponse({
    required this.id,
    required this.createdAt,
    required this.userId,
    required this.username,
    required this.firstname,
    required this.lastname,
    required this.content,
  });

  @override
  List<Object?> get props =>
      [id, createdAt, userId, username, firstname, lastname, content];

  /// Creates a ActivityCommentResponse object from a JSON map.
  factory ActivityCommentResponse.fromMap(Map<String, dynamic> map) {
    final user = map['user'] as Map<String, dynamic>? ?? {};
    return ActivityCommentResponse(
      id: map['id'].toString(),
      createdAt: DateTime.parse(map['createdAt']),
      userId: user['id'].toString(),
      username: user['username']?.toString() ?? '',
      firstname: user['firstname']?.toString(),
      lastname: user['lastname']?.toString(),
      content: map['content'].toString(),
    );
  }

  /// Converts the ActivityCommentResponse object to a ActivityComment entity.
  ActivityComment toEntity() {
    return ActivityComment(
      id: id,
      createdAt: createdAt,
      user: User(
        id: userId,
        username: username,
        firstname: firstname,
        lastname: lastname,
      ),
      content: content,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'user': {
        'id': userId,
        'username': username,
        'firstname': firstname,
        'lastname': lastname,
      },
      'content': content,
    };
  }
}
