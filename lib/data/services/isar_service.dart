import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';


final isarServiceProvider = Provider<IsarService>((ref) => IsarService());

/// Service responsible for managing the Isar database instance.
class IsarService {
  static const String databaseName = 'run_tracking';

  Isar? _isar;

  /// Returns the singleton Isar instance, initializing it if needed.
  Future<Isar> getInstance() async {
    if (_isar != null) {
      return _isar!;
    }

    final directory = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [],
      directory: directory.path,
      name: databaseName,
    );

    return _isar!;
  }

  /// Returns the underlying database file for backup operations.
  Future<File> getDatabaseFile() async {
    final isar = await getInstance();
    return File('${isar.directory}/${isar.name}.isar');
  }

  /// Closes the active Isar instance.
  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
