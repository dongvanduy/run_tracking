import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';

import '../../../domain/entities/user.dart';

/// Represents a response object for a user.
part 'user_response.g.dart';

@collection
class UserResponse extends Equatable {
  /// Isar database identifier.
  Id isarId = Isar.autoIncrement;

  /// The ID of the user.
  late String id;

  /// The firstname of the user
  String? firstname;

  /// The lastname of the user
  String? lastname;

  /// The username of the user
  late String username;

  /// Constructs an UserResponse object with the given parameters.
  UserResponse({
    required this.id,
    required this.username,
    required this.firstname,
    required this.lastname,
  });

  @override
  List<Object?> get props => [id, username];

  /// Creates an UserResponse object from a JSON map.
  factory UserResponse.fromMap(Map<String, dynamic> map) {
    return UserResponse(
        id: map['id'].toString(),
        username: map['username'],
        firstname: map['firstname'],
        lastname: map['lastname']);
  }

  /// Converts the UserResponse object to a User entity.
  User toEntity() {
    return User(
        id: id, username: username, firstname: firstname, lastname: lastname);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'firstname': firstname,
      'lastname': lastname,
    };
  }
}
