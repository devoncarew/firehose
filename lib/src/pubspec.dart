import 'dart:io';

import 'package:yaml/yaml.dart' as yaml;
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

class Pubspec {
  Directory directory;

  Pubspec(this.directory);

  /// Return the package version.
  ///
  /// Returns null if no version is specified.
  Version? get version {
    var pubspec = yaml.loadYaml(
            File(path.join(directory.path, 'pubspec.yaml')).readAsStringSync())
        as Map;

    var version = pubspec['version'] as String?;
    if (version == null) {
      return null;
    }
    return Version.parse(version);
  }
}
