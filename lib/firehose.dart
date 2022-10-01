import 'dart:io';

import 'package:firehose/src/packages.dart';

import 'src/changelog.dart';
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
    print('changed files');
    for (var file in changedFiles) {
      print('- $file');
    }

    var packages = Packages().locatePackages();
    print('all publishable repo packages');
    for (var package in packages) {
      print('- $package');
    }

    var changedPackages = _calculateChangedPackages(packages, changedFiles);
    print('');
    print('${changedPackages.length} changed packages');

    for (var package in changedPackages) {
      print('');
      print(package.pubspec.name);
      var files = package.matchingFiles(changedFiles);
      for (var file in files) {
        print('  $file');
      }
      print('pubspec version: ${package.pubspec.version}');
      print('changelog version: ${package.changelog.latestVersion}');
      // todo: pubspec changed?
      // todo: print changelog entry?
      // - validate that there's a changelog entry
      // - validate that the changelog version == the pubspec version
      // - validate that the pubspec version != a published version
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
    scratch();
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
}

void scratch() {
  var git = Git();
  print('git.baseRef: ${git.baseRef}');
  print('git.headRef: ${git.headRef}');
  print('git.ref: ${git.ref}');
  print('git.refName: ${git.refName}');

  print('');
  print('changed files:');
  for (var file in git.getChangedFiles()) {
    print('  $file');
  }

  var changelog = Changelog(File('CHANGELOG.md'));
  print('');
  print('changelog title: ${changelog.latestVersion}');
  print('entries: [${changelog.latestChangeEntries.join('\n')}]');
}
