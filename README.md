# Providers Register

A code generation library for Riverpod providers. It generates a structured way to access your providers with type safety and convenience.

```dart
// Read (one-time access)
final settingsState = ref.providers.read.settings;
// Watch (reactive updates)
final serverState = ref.providers.watch.server;
// Use notifiers (for state changes)
final serverNotifier = ref.providers.use.server;
```

## Usage

### 1. Configure Generation (Optional)

In your `pubspec.yaml`, optionally configure the generation:

```yaml
riverpod_reg:
  class_name: "AppProviders"  # Default: "MyProviders"
  gen_path: "lib/data/providers.dart"  # Default: "lib/riverpod_reg.dart"
```

### 2. Annotate Your Providers

Use `@registerProvider` to mark providers for generation:

```dart
import 'package:riverpod_reg/riverpod_reg.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'server_provider.g.dart';

@riverpod
@registerProvider  // Mark for generation
class ServerNotifier extends _$ServerNotifier {
  @override
  ServerState build() => const ServerState();
}

@RegisterProvider(name: 'settings')  // Custom name
final settingsProvider = Provider<SettingsState>((ref) => const SettingsState());
```

### 3. Generate Code

Run build_runner to generate the providers:

```bash
dart run build_runner build
```

### 4. Use Generated Providers

The generated code provides three access patterns:

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read (one-time access)
    final serverState = ref.providers.read.server;
    final settingsState = ref.providers.read.settings;
    
    // Watch (reactive updates)
    final serverState = ref.providers.watch.server;
    
    // Use notifiers (for state changes)
    final serverNotifier = ref.providers.use.server;
    
    return YourWidget();
  }
}
```

## Annotation Options

### `@RegisterProvider`

```dart
class RegisterProvider {
  final String? type;           // Provider type (auto-detected)
  final String? name;           // Custom accessor name
  final bool includeRead;       // Include in read operations (default: true)
  final bool includeWatch;      // Include in watch operations (default: true)  
  final bool includeNotifier;   // Include in notifier operations (default: true)
}
```

### Examples

```dart
// Basic registration
@registerProvider
final myProvider = Provider<MyState>((ref) => MyState());

// Custom name
@RegisterProvider(name: 'customName')
final myLongProviderName = Provider<MyState>((ref) => MyState());

// Exclude from watch operations
@RegisterProvider(includeWatch: false)
final myReadOnlyProvider = Provider<MyState>((ref) => MyState());

// Notifier only
@RegisterProvider(includeRead: false, includeWatch: false)
final myNotifierProvider = NotifierProvider<MyNotifier, MyState>(MyNotifier.new);
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
