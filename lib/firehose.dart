import 'dart:io';

import 'package:firehose/src/packages.dart';

import 'src/git.dart';

class Firehose {
  final Directory directory;

  Firehose(this.directory);

  void verify() {
// for a PR:
// - determine changed files
// - determine affected packages
// - validate that there's a changelog entry
// - validate that the changelog version == the pubspec version
// - validate that the pubspec version != a published version

    var git = Git();

    var changedFiles = git.getChangedFiles();
    print('Repository changed files:');
    for (var file in changedFiles) {
      print('- $file');
    }

    var packages = Packages().locatePackages();
    print('');
    print('Repository publishable packages:');
    for (var package in packages) {
      print('- $package');
    }

    var changedPackages = _calculateChangedPackages(packages, changedFiles);
    print('');
    print('Found ${changedPackages.length} changed package(s).');

    for (var package in changedPackages) {
      print('');
      print('Validating ${_bold('package:{package.pubspec.name}')}');

      print('pubspec:');
      print('  version: ${_bold(package.pubspec.version.toString())}');
      if (package.pubspec.autoPublishValue != null) {
        print('  auto_publish: ${package.pubspec.autoPublishValue}');
      }
      if (package.pubspec.publishToValue != null) {
        print('  publish_to: ${package.pubspec.publishToValue}');
      }

      var files = package.matchingFiles(changedFiles);

      print('changelog:');
      print('  version: ${_bold(package.changelog.latestVersion)}');
      var changelogUpdated = files.contains('CHANGELOG.md');
      if (changelogUpdated) {
        if (package.changelog.latestVersion != null) {
          print('  ## ${package.changelog.latestVersion}');
        }
        for (var entry in package.changelog.latestChangeEntries) {
          print('  $entry');
        }
      }

      print('changed files:');
      for (var file in files) {
        print('  $file');
      }

      // checks
      if (!changelogUpdated) {
        _failure('No changelog update for this change.');
      }
      if (package.pubspec.version.toString() !=
          package.changelog.latestVersion) {
        _failure("pubspec version (${package.pubspec.version}) and "
            "changelog (${package.changelog.latestVersion})don't agree.");
      }
    }
  }

  void publish() {
// for the default branch:
// - determine changed files
// - determine affected packages
// - validate that the pubspec version != a published version
// - attempt to publish

    // todo:
    print('todo: publish');
    print('');
    verify();
  }

  List<Package> _calculateChangedPackages(
    List<Package> packages,
    List<String> changedFiles,
  ) {
    var results = <Package>{};
    for (var package in packages) {
      for (var file in changedFiles) {
        if (package.containsFile(file)) {
          results.add(package);
        }
      }
    }
    return results.toList();
  }

  void _failure(String message) {
    print('\u001b[31merror: $message\u001b[0m');
    exitCode = 1;
  }

  String _bold(String? message) {
    return '\u001b[1m$message\u001b[0m';
  }
}
