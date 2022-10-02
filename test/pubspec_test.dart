import 'dart:io';

import 'package:firehose/src/pubspec.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('pubspec', () {
    late Pubspec pubspec;

    setUp(() {
      pubspec = Pubspec(Directory.current);
    });

    test('name', () {
      var name = pubspec.name;
      expect(name, isNotNull);
      expect(name, equals('firehose'));
    });

    test('version', () {
      var version = pubspec.version;
      expect(version, isNotNull);
    });

    test('hasValidSemverVersion', () {
      var valid = pubspec.hasValidSemverVersion;
      expect(valid, isTrue);
    });

    test('semverVersion', () {
      var version = pubspec.semverVersion;
      expect(version, isNotNull);
      expect(version, greaterThan(Version.none));
    });

    test('autoPublishValue', () {
      var value = pubspec.autoPublishValue;
      expect(value, isNotNull);
      expect(value, equals(true));
    });

    test('publishToValue', () {
      var value = pubspec.publishToValue;
      expect(value, isNull);
    });
  });
}
