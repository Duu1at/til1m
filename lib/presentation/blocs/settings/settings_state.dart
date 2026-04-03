part of 'settings_cubit.dart';

sealed class SettingsState extends Equatable {
  const SettingsState();
}

final class SettingsInitial extends SettingsState {
  const SettingsInitial();
  @override
  List<Object?> get props => [];
}

final class SettingsLoading extends SettingsState {
  const SettingsLoading();
  @override
  List<Object?> get props => [];
}

final class SettingsLoaded extends SettingsState {
  const SettingsLoaded(this.settings);

  final UserSettings settings;

  @override
  List<Object?> get props => [settings];
}
