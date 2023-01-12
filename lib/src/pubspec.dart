import 'dart:io';

import 'package:yaml/yaml.dart' as yaml;
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

class Pubspec {
  Directory directory;
  late Map _yaml;

  Pubspec(this.directory) {
    _yaml = yaml.loadYaml(File(localFilePath).readAsStringSync()) as Map;
  }

  String get localFilePath {
    var p = path.join(directory.path, 'pubspec.yaml');
    return path.relative(p);
  }

  int? get versionLine {
    var lines = File(localFilePath).readAsLinesSync();
    lines = lines.map((line) => line.split(':').first.trim()).toList();
    var index = lines.indexOf('version');
    return index == -1 ? null : index + 1;
  }

  /// Return the package name.
  String get name => _yaml['name'];

  /// Returns whether the pubspec semver version is a pre-release version
  /// (`'1.2.3-foo'`).
  bool get isPreRelease => semverVersion?.isPreRelease ?? false;

  /// Return the `'auto_publish'`, if any.
  Object? get autoPublishValue => _yaml['auto_publish'];

  /// Return the `'publish_to'`, if any.
  Object? get publishToValue => _yaml['publish_to'];

  /// Return the package version.
  ///
  /// Returns null if no version is specified.
  String? get version => _yaml['version'] as String?;

  /// Returns whether the 'version' field is populated with a valid semver
  /// value.
  bool get hasValidSemverVersion {
    if (version == null) {
      return false;
    }
    try {
      semverVersion;
      return true;
    } on FormatException catch (_) {
      return false;
    }
  }

  /// Return the package version.
  ///
  /// Returns null if no version is specified. This will throw a FormatException
  /// if the 'version' field is populated with an invalid semver value.
  Version? get semverVersion {
    return version == null ? null : Version.parse(version!);
  }
}
