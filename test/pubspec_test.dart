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

    test('version', () {
      var version = pubspec.version;
      expect(version, isNotNull);
      expect(version, greaterThan(Version.none));
    });
  });
}
