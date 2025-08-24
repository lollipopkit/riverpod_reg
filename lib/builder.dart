import 'package:build/build.dart';
import 'package:providers_register/src/generator.dart';
import 'package:source_gen/source_gen.dart';

Builder providersRegisterBuilder(BuilderOptions options) =>
    SharedPartBuilder([], 'providers_register');

Builder providersFileBuilder(BuilderOptions options) => ProvidersFileBuilder();
