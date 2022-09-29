import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart' as yaml;

class Package {
  // Package
  final Directory directory;
  final bool publishingEnabled;

  Package(
    this.directory, {
    this.publishingEnabled = true,
  });
}

class Packages {
  /// This will return all the potentially publishable packages for the current
  /// repository.
  ///
  /// This could be one package - if this is a single package repository - or
  /// multiple packages, if this is a monorepo.
  ///
  /// Package will only be returned if their pubspec contains an 'auto-publish'
  /// key. If that 'auto_publish' key is set to `false`, the package will still
  /// be returned, but its Package.publishingEnabled flag will be false.
  List<Package> locatePackages() {
    return _recurseAndGather(Directory.current, []);
  }

  List<Package> _recurseAndGather(Directory directory, List<Package> packages) {
    var pubspecFile = File(path.join(directory.path, 'pubspec.yaml'));

    if (pubspecFile.existsSync()) {
      var pubspec = yaml.loadYaml(pubspecFile.readAsStringSync()) as Map;
      if (pubspec.containsKey('auto_publish')) {
        var publishable = pubspec['auto_publish'] == true;
        packages.add(Package(directory, publishingEnabled: publishable));
      }
    } else {
      for (var child in directory.listSync().whereType<Directory>()) {
        var name = path.basename(child.path);
        if (!name.startsWith('.')) {
          _recurseAndGather(child, packages);
        }
      }
    }

    return packages;
  }
}
