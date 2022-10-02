import 'dart:io';

import 'package:firehose/src/changelog.dart';
import 'package:test/test.dart';

void main() {
  group('changelog', () {
    late Changelog changelog;

    setUp(() {
      changelog = Changelog(File('CHANGELOG.md'));
    });

    test('exists', () {
      var version = changelog.exists;
      expect(version, isTrue);
    });

    test('latestVersion', () {
      var version = changelog.latestVersion;
      expect(version, isNotNull);
    });

    test('latestChangeEntries', () {
      var version = changelog.latestChangeEntries;
      expect(version, isNotEmpty);
    });
  });
}
