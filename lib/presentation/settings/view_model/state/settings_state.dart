class SettingsState {
  final bool isLoading;
  final bool isBackupLoading;
  final bool isRestoreLoading;

  /// Represents the state of the settings screen.
  ///
  /// [isLoading] indicates whether the screen is in a loading state.
  const SettingsState({
    required this.isLoading,
    required this.isBackupLoading,
    required this.isRestoreLoading,
  });

  /// Creates an initial state for the settings screen.
  factory SettingsState.initial() {
    return const SettingsState(
      isLoading: false,
      isBackupLoading: false,
      isRestoreLoading: false,
    );
  }

  /// Creates a copy of this state object with the provided changes.
  SettingsState copyWith({
    bool? isLoading,
    bool? isBackupLoading,
    bool? isRestoreLoading,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      isBackupLoading: isBackupLoading ?? this.isBackupLoading,
      isRestoreLoading: isRestoreLoading ?? this.isRestoreLoading,
    );
  }
}
