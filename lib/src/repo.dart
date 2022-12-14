import 'dart:io';

import 'package:firehose/src/changelog.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart' as yaml;

import 'pubspec.dart';

class Package {
  final Directory directory;
  final bool publishingEnabled;

  late final Pubspec pubspec;
  late final Changelog changelog;

  Package(
    this.directory, {
    this.publishingEnabled = true,
  }) {
    pubspec = Pubspec(directory);
    changelog = Changelog(File(path.join(directory.path, 'CHANGELOG.md')));
  }

  String get name => pubspec.name;

  bool containsFile(String file) {
    return path.isWithin(directory.path, file);
  }

  List<String> matchingFiles(List<String> changedFiles) {
    var fullPath = directory.absolute.path;
    return changedFiles.where((file) => containsFile(file)).map((file) {
      return File(file).absolute.path.substring(fullPath.length + 1);
    }).toList();
  }

  @override
  String toString() {
    var notPublishable = publishingEnabled ? '' : ' [publishing disabled]';
    return 'package:${pubspec.name}, ${pubspec.version}, '
        '${path.relative(directory.path)}$notPublishable';
  }
}

class Repo {
  /// Returns true if this repository hosts only a single package, and that
  /// package lives at the top level of the repo.
  bool get singlePackageRepo {
    var packages = locatePackages();
    if (packages.length != 1) {
      return false;
    }

    var dir = packages.single.directory;
    return dir.absolute.path == Directory.current.absolute.path;
  }

  /// This will return all the potentially publishable packages for the current
  /// repository.
  ///
  /// This could be one package - if this is a single package repository - or
  /// multiple packages, if this is a monorepo.
  ///
  /// Packages will only be returned if their pubspec contains an 'auto-publish'
  /// key with a value of `true`. If that 'auto_publish' key is set to `false`,
  /// the package will still be returned, but its Package.publishingEnabled flag
  /// will be false.
  List<Package> locatePackages() {
    return _recurseAndGather(Directory.current, []);
  }

  List<Package> _recurseAndGather(Directory directory, List<Package> packages) {
    var pubspecFile = File(path.join(directory.path, 'pubspec.yaml'));

    if (pubspecFile.existsSync()) {
      var pubspec = yaml.loadYaml(pubspecFile.readAsStringSync()) as Map;
      if (pubspec.containsKey('auto_publish')) {
        var publishable = pubspec['auto_publish'] == true;
        // check for 'publish_to: none'
        if (pubspec['publish_to'] == 'none') {
          publishable = false;
        }
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
