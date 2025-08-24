import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_reg/riverpod_reg.dart';

part 'app_provider.g.dart';

class AppState {
  final String theme;
  final bool isDarkMode;
  
  const AppState({
    this.theme = 'system',
    this.isDarkMode = false,
  });
}

@riverpod
@registerProvider
class AppStates extends _$AppStates {
  @override
  AppState build() => const AppState();
}

class SettingsState {
  final Map<String, dynamic> preferences;
  
  const SettingsState({
    this.preferences = const {},
  });
}

@RegisterProvider(name: 'settings')
final settingsProvider = Provider<SettingsState>((ref) => const SettingsState());
