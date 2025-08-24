import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/server_provider.dart';
import '../../providers/app_provider.dart';

extension RiverpodNotifiersWidget on WidgetRef {
  AppProviders get providers => AppProviders(this);
}

extension RiverpodNotifiers on ConsumerState {
  T useNotifier<T extends Notifier<Object?>>(NotifierProvider<T, Object?> provider) {
    return ref.read(provider.notifier);
  }

  T readProvider<T>(ProviderBase<T> provider) {
    return ref.read(provider);
  }

  T watchProvider<T>(ProviderBase<T> provider) {
    return ref.watch(provider);
  }

  AppProviders get providers => ref.providers;
}

final class AppProviders {
  final WidgetRef ref;
  const AppProviders(this.ref);

  ReadAppProviders get read => ReadAppProviders(ref);
  WatchAppProviders get watch => WatchAppProviders(ref);
  UseNotifierAppProviders get use => UseNotifierAppProviders(ref);
}

final class ReadAppProviders {
  final WidgetRef ref;
  const ReadAppProviders(this.ref);

  T call<T>(ProviderBase<T> provider) => ref.read(provider);

  // Specific provider getters
  ServerState get server => ref.read(serverNotifierProvider);
  AppState get appStates => ref.read(appStatesProvider);
}

final class WatchAppProviders {
  final WidgetRef ref;
  const WatchAppProviders(this.ref);

  T call<T>(ProviderBase<T> provider) => ref.watch(provider);

  // Specific provider getters
  ServerState get server => ref.watch(serverNotifierProvider);
  AppState get appStates => ref.watch(appStatesProvider);
}

final class UseNotifierAppProviders {
  final WidgetRef ref;
  const UseNotifierAppProviders(this.ref);

  T call<T extends Notifier<Object?>>(NotifierProvider<T, Object?> provider) =>
      ref.read(provider.notifier);

  // Specific provider notifier getters
  ServerNotifier get server => ref.read(serverNotifierProvider.notifier);
  AppStates get appStates => ref.read(appStatesProvider.notifier);
}
