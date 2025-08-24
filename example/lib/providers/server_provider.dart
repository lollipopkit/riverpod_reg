import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_reg/riverpod_reg.dart';

part 'server_provider.g.dart';

@riverpod
@registerProvider
class ServerNotifier extends _$ServerNotifier {
  @override
  ServerState build() => const ServerState();
}

class ServerState {
  final List<String> servers;
  final bool isLoading;
  
  const ServerState({
    this.servers = const [],
    this.isLoading = false,
  });
}