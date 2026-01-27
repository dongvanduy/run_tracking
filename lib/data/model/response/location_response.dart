import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';

import '../../../domain/entities/location.dart';

/// Represents a response object for a location.
part 'location_response.g.dart';

@collection
class LocationResponse extends Equatable {
  /// Isar database identifier.
  Id isarId = Isar.autoIncrement;

  /// The ID of the location.
  late String id;

  /// The datetime of the location.
  late DateTime datetime;

  /// The latitude of the location.
  late double latitude;

  /// The longitude of the location.
  late double longitude;

  /// Constructs a LocationResponse object with the given parameters.
  LocationResponse({
    required this.id,
    required this.datetime,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [
        id,
        datetime,
        latitude,
        longitude,
      ];

  /// Creates a LocationResponse object from a JSON map.
  factory LocationResponse.fromMap(Map<String, dynamic> map) {
    return LocationResponse(
      id: map['id'].toString(),
      datetime: DateTime.parse(map['datetime']),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Converts the LocationResponse object to a Location entity.
  Location toEntity() {
    return Location(
      id: id,
      datetime: datetime,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'datetime': datetime.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
