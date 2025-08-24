import 'package:build/build.dart';
import 'package:riverpod_reg/src/generator.dart';
import 'package:source_gen/source_gen.dart';

Builder providersRegisterBuilder(BuilderOptions options) =>
    SharedPartBuilder([], 'riverpod_reg');

Builder providersFileBuilder(BuilderOptions options) => ProvidersFileBuilder();
