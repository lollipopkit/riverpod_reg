import 'package:test/test.dart';
import 'package:riverpod_reg/src/annotations.dart';

void main() {
  group('RegisterProvider', () {
    test('should create annotation with default values', () {
      const annotation = RegisterProvider();
      
      expect(annotation.type, isNull);
      expect(annotation.name, isNull);
      expect(annotation.includeRead, isTrue);
      expect(annotation.includeWatch, isTrue);
      expect(annotation.includeNotifier, isTrue);
    });

    test('should create annotation with custom values', () {
      const annotation = RegisterProvider(
        type: 'NotifierProvider',
        name: 'customName',
        includeRead: false,
        includeWatch: true,
        includeNotifier: false,
      );
      
      expect(annotation.type, equals('NotifierProvider'));
      expect(annotation.name, equals('customName'));
      expect(annotation.includeRead, isFalse);
      expect(annotation.includeWatch, isTrue);
      expect(annotation.includeNotifier, isFalse);
    });

    test('registerProvider constant should have default values', () {
      expect(registerProvider.type, isNull);
      expect(registerProvider.name, isNull);
      expect(registerProvider.includeRead, isTrue);
      expect(registerProvider.includeWatch, isTrue);
      expect(registerProvider.includeNotifier, isTrue);
    });
  });
}