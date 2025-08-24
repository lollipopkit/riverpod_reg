import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:providers_register/src/annotations.dart';
import 'package:source_gen/source_gen.dart';
import 'package:yaml/yaml.dart';

class ProvidersGenerator extends GeneratorForAnnotation<RegisterProvider> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    // This generator collects all annotated providers and generates a single file
    // We'll implement the actual generation logic in a separate builder
    return '';
  }
}

/// Generates the providers file based on all collected providers
class ProvidersFileBuilder extends Builder {
  
  @override
  Map<String, List<String>> get buildExtensions => const {
    r'$lib$': ['generated_providers.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final config = await _loadConfig(buildStep);
    final providers = await _collectProviders(buildStep);
    
    if (providers.isEmpty) return;
    
    final output = _generateProvidersFile(providers, config);
    // Use the build_extensions defined path, ignore config.genPath for now
    const outputPath = 'lib/generated_providers.dart';
    
    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, outputPath),
      output,
    );
  }

  Future<ProvidersConfig> _loadConfig(BuildStep buildStep) async {
    try {
      final pubspecId = AssetId(buildStep.inputId.package, 'pubspec.yaml');
      final pubspecContent = await buildStep.readAsString(pubspecId);
      final pubspec = loadYaml(pubspecContent) as Map;
      
      final config = pubspec['register_providers'] as Map?;
      return ProvidersConfig(
        className: config?['class_name'] as String? ?? 'MyProviders',
        genPath: config?['gen_path'] as String?,
      );
    } catch (e) {
      return ProvidersConfig();
    }
  }

  Future<List<ProviderInfo>> _collectProviders(BuildStep buildStep) async {
    final providers = <ProviderInfo>[];
    final imports = <String>{};
    
    final glob = Glob('lib/**/*.dart');
    await for (final input in buildStep.findAssets(glob)) {
      // Skip generated files
      if (input.path.endsWith('.g.dart') || 
          input.path.endsWith('.freezed.dart') ||
          input.path.contains('generated_providers.dart')) {
        continue;
      }
      
      final library = await buildStep.resolver.libraryFor(input);
      
      for (final element in library.topLevelElements) {
        RegisterProvider? annotation;
        
        if (element is VariableElement) {
          annotation = _getRegisterProviderAnnotation(element);
          if (annotation != null) {
            final providerInfo = _createVariableProviderInfo(element, annotation, input.path);
            if (providerInfo != null) {
              providers.add(providerInfo);
              imports.add(input.path);
            }
          }
        } else if (element is ClassElement) {
          annotation = _getRegisterProviderAnnotation(element);
          if (annotation != null) {
            final providerInfo = _createClassProviderInfo(element, annotation, input.path);
            if (providerInfo != null) {
              providers.add(providerInfo);
              imports.add(input.path);
            }
          }
        }
      }
    }
    
    // Store imports in the providers for later use
    for (final provider in providers) {
      provider.importPath = imports.firstWhere((import) => 
        import.contains(provider.sourceFile ?? ''), 
        orElse: () => '');
    }
    
    return providers;
  }

  RegisterProvider? _getRegisterProviderAnnotation(Element element) {
    for (final metadata in element.metadata) {
      final value = metadata.computeConstantValue();
      if (value?.type?.element?.name == 'RegisterProvider') {
        return RegisterProvider(
          type: value?.getField('type')?.toStringValue(),
          name: value?.getField('name')?.toStringValue(),
          includeRead: value?.getField('includeRead')?.toBoolValue() ?? true,
          includeWatch: value?.getField('includeWatch')?.toBoolValue() ?? true,
          includeNotifier: value?.getField('includeNotifier')?.toBoolValue() ?? true,
        );
      }
    }
    return null;
  }

  ProviderInfo? _createVariableProviderInfo(VariableElement element, RegisterProvider annotation, String sourcePath) {
    final providerName = element.name;
    final returnType = _extractReturnType(element.type);
    final notifierType = _extractNotifierType(element.type);
    
    if (returnType == null) return null;
    
    return ProviderInfo(
      providerName: providerName,
      displayName: annotation.name ?? _generateDisplayName(providerName),
      returnType: returnType,
      notifierType: notifierType,
      includeRead: annotation.includeRead,
      includeWatch: annotation.includeWatch,
      includeNotifier: annotation.includeNotifier && notifierType != null,
      sourceFile: sourcePath,
    );
  }

  ProviderInfo? _createClassProviderInfo(ClassElement element, RegisterProvider annotation, String sourcePath) {
    // For classes like AppStates, we need to find the generated provider
    final className = element.name;
    final providerName = '${_camelCase(className)}Provider';
    
    // Extract state type from the class - look for build method return type
    String? returnType;
    for (final method in element.methods) {
      if (method.name == 'build') {
        returnType = method.returnType.getDisplayString();
        break;
      }
    }
    
    if (returnType == null) return null;
    
    return ProviderInfo(
      providerName: providerName,
      displayName: annotation.name ?? _generateDisplayName(providerName),
      returnType: returnType,
      notifierType: className,
      includeRead: annotation.includeRead,
      includeWatch: annotation.includeWatch,
      includeNotifier: annotation.includeNotifier,
      sourceFile: sourcePath,
    );
  }

  String _camelCase(String input) {
    if (input.isEmpty) return input;
    return input[0].toLowerCase() + input.substring(1);
  }

  String? _extractReturnType(DartType type) {
    // Extract the state type from provider type
    final typeArgs = type is ParameterizedType ? type.typeArguments : <DartType>[];
    if (typeArgs.length >= 2) {
      return typeArgs[1].getDisplayString();
    }
    return null;
  }

  String? _extractNotifierType(DartType type) {
    // Extract the notifier type from NotifierProvider
    final typeArgs = type is ParameterizedType ? type.typeArguments : <DartType>[];
    if (typeArgs.isNotEmpty && type.element?.name?.contains('NotifierProvider') == true) {
      return typeArgs[0].getDisplayString();
    }
    return null;
  }

  String _generateDisplayName(String providerName) {
    // Convert from camelCase provider name to display name
    // e.g., serverNotifierProvider -> server
    return providerName
        .replaceAll('Provider', '')
        .replaceAll('Notifier', '')
        .toLowerCase();
  }

  String _generateProvidersFile(List<ProviderInfo> providers, ProvidersConfig config) {
    final buffer = StringBuffer();
    
    // Generate imports
    buffer.writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';");
    buffer.writeln();
    
    // Generate actual provider imports
    final imports = providers.map((p) => p.sourceFile).where((path) => path != null).toSet();
    for (final importPath in imports) {
      // Convert absolute path to relative path from lib/
      final relativePath = importPath?.replaceFirst('lib/', '') ?? '';
      buffer.writeln("import '$relativePath';");
    }
    buffer.writeln();
    
    // Generate extension
    buffer.writeln('extension RiverpodNotifiersWidget on WidgetRef {');
    buffer.writeln('  ${config.className} get providers => ${config.className}(this);');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('extension RiverpodNotifiers on ConsumerState {');
    buffer.writeln('  T useNotifier<T extends Notifier<Object?>>(NotifierProvider<T, Object?> provider) {');
    buffer.writeln('    return ref.read(provider.notifier);');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  T readProvider<T>(ProviderBase<T> provider) {');
    buffer.writeln('    return ref.read(provider);');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  T watchProvider<T>(ProviderBase<T> provider) {');
    buffer.writeln('    return ref.watch(provider);');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  ${config.className} get providers => ref.providers;');
    buffer.writeln('}');
    buffer.writeln();
    
    // Generate main provider class
    buffer.writeln('final class ${config.className} {');
    buffer.writeln('  final WidgetRef ref;');
    buffer.writeln('  const ${config.className}(this.ref);');
    buffer.writeln();
    buffer.writeln('  Read${config.className} get read => Read${config.className}(ref);');
    buffer.writeln('  Watch${config.className} get watch => Watch${config.className}(ref);');
    buffer.writeln('  UseNotifier${config.className} get use => UseNotifier${config.className}(ref);');
    buffer.writeln('}');
    buffer.writeln();
    
    // Generate Read class
    _generateReadClass(buffer, providers, config.className);
    
    // Generate Watch class  
    _generateWatchClass(buffer, providers, config.className);
    
    // Generate UseNotifier class
    _generateUseNotifierClass(buffer, providers, config.className);
    
    return buffer.toString();
  }

  void _generateReadClass(StringBuffer buffer, List<ProviderInfo> providers, String className) {
    buffer.writeln('final class Read$className {');
    buffer.writeln('  final WidgetRef ref;');
    buffer.writeln('  const Read$className(this.ref);');
    buffer.writeln();
    buffer.writeln('  T call<T>(ProviderBase<T> provider) => ref.read(provider);');
    buffer.writeln();
    buffer.writeln('  // Specific provider getters');
    
    for (final provider in providers.where((p) => p.includeRead)) {
      buffer.writeln('  ${provider.returnType} get ${provider.displayName} => ref.read(${provider.providerName});');
    }
    
    buffer.writeln('}');
    buffer.writeln();
  }

  void _generateWatchClass(StringBuffer buffer, List<ProviderInfo> providers, String className) {
    buffer.writeln('final class Watch$className {');
    buffer.writeln('  final WidgetRef ref;');
    buffer.writeln('  const Watch$className(this.ref);');
    buffer.writeln();
    buffer.writeln('  T call<T>(ProviderBase<T> provider) => ref.watch(provider);');
    buffer.writeln();
    buffer.writeln('  // Specific provider getters');
    
    for (final provider in providers.where((p) => p.includeWatch)) {
      buffer.writeln('  ${provider.returnType} get ${provider.displayName} => ref.watch(${provider.providerName});');
    }
    
    buffer.writeln('}');
    buffer.writeln();
  }

  void _generateUseNotifierClass(StringBuffer buffer, List<ProviderInfo> providers, String className) {
    buffer.writeln('final class UseNotifier$className {');
    buffer.writeln('  final WidgetRef ref;');
    buffer.writeln('  const UseNotifier$className(this.ref);');
    buffer.writeln();
    buffer.writeln('  T call<T extends Notifier<Object?>>(NotifierProvider<T, Object?> provider) =>');
    buffer.writeln('      ref.read(provider.notifier);');
    buffer.writeln();
    buffer.writeln('  // Specific provider notifier getters');
    
    for (final provider in providers.where((p) => p.includeNotifier && p.notifierType != null)) {
      buffer.writeln('  ${provider.notifierType} get ${provider.displayName} => ref.read(${provider.providerName}.notifier);');
    }
    
    buffer.writeln('}');
  }
}

class ProvidersConfig {
  final String className;
  final String? genPath;
  
  const ProvidersConfig({
    this.className = 'MyProviders',
    this.genPath,
  });
}

class ProviderInfo {
  final String providerName;
  final String displayName;
  final String returnType;
  final String? notifierType;
  final bool includeRead;
  final bool includeWatch;
  final bool includeNotifier;
  final String? sourceFile;
  String? importPath;
  
  ProviderInfo({
    required this.providerName,
    required this.displayName,
    required this.returnType,
    this.notifierType,
    required this.includeRead,
    required this.includeWatch,
    required this.includeNotifier,
    this.sourceFile,
  });
}