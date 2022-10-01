import 'dart:io';

import 'package:yaml/yaml.dart' as yaml;
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

class Pubspec {
  Directory directory;
  late Map _yaml;

  Pubspec(this.directory) {
    _yaml = yaml.loadYaml(
            File(path.join(directory.path, 'pubspec.yaml')).readAsStringSync())
        as Map;
  }

  /// Return the package name.
  String get name => _yaml['name'];

  /// Return the `'auto_publish'`, if any.
  Object? get autoPublishValue => _yaml['auto_publish'];

  /// Return the `'publish_to'`, if any.
  Object? get publishToValue => _yaml['publish_to'];

  /// Return the package version.
  ///
  /// Returns null if no version is specified.
  Version? get version {
    var version = _yaml['version'] as String?;
    if (version == null) {
      return null;
    }
    return Version.parse(version);
  }
}
