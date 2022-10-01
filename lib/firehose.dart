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
    print('');
    print('all publishable repo packages');
    for (var package in packages) {
      print('- $package');
    }

    var changedPackages = _calculateChangedPackages(packages, changedFiles);
    print('');
    print('${changedPackages.length} changed packages');

    void failure(String message) {
      stderr.writeln('error: $message');
      exitCode = 1;
    }

    String bold(String? message) {
      return '\u001b[1m$message\u001b[0m';
    }

    for (var package in changedPackages) {
      print('');
      print(bold(package.pubspec.name));
      print('pubspec version: ${bold(package.pubspec.version.toString())}');
      var files = package.matchingFiles(changedFiles);
      print('files:');
      for (var file in files) {
        print('  $file');
      }
      print('changelog version: ${bold(package.changelog.latestVersion)}');
      var changelogUpdated = files.contains('CHANGELOG.md');
      if (!changelogUpdated) {
        failure('No changelog update for this change.');
      }
      if (package.pubspec.version.toString() !=
          package.changelog.latestVersion) {
        failure("pubspec version and changelog don't agree.");
      }
      if (changelogUpdated) {
        for (var entry in package.changelog.latestChangeEntries) {
          print(entry);
        }
      }

      // todo:
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
