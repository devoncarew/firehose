import 'dart:convert';
import 'dart:io' hide exitCode;
import 'dart:io' as io show exitCode;

import 'package:firehose/src/packages.dart';
import 'package:path/path.dart' as path;

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
      print('  $package');
    }

    var changedPackages = _calculateChangedPackages(packages, changedFiles);
    print('');
    print('Found ${changedPackages.length} changed package(s).');

    for (var package in changedPackages) {
      print('');
      print('Validating ${_bold('package:${package.pubspec.name}')}');

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
      var changelogUpdated = files.contains('CHANGELOG.md');
      if (changelogUpdated) {
        if (package.changelog.latestVersion != null) {
          print('  ## ${_bold(package.changelog.latestVersion)}');
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
      var issues = 0;
      if (!changelogUpdated) {
        issues++;
        _failure('No changelog update for this change.');
      }
      if (package.pubspec.version.toString() !=
          package.changelog.latestVersion) {
        issues++;
        _failure("pubspec version (${package.pubspec.version}) and "
            "changelog (${package.changelog.latestVersion})don't agree.");
      }
      if (issues == 0) {
        print('No issues found.');
      }
    }
  }

  // todo: figure out how to share code between verify() and publish()

  void publish() async {
// for the default branch:
// - determine changed files
// - determine affected packages
// - validate that the pubspec version != a published version
// - attempt to publish

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
      print('  $package');
    }

    var changedPackages = _calculateChangedPackages(packages, changedFiles);
    print('');
    print('Found ${changedPackages.length} changed package(s).');

    for (var package in changedPackages) {
      print('');
      print('Publishing ${_bold('package:${package.pubspec.name}')}');

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
      var changelogUpdated = files.contains('CHANGELOG.md');
      if (changelogUpdated) {
        if (package.changelog.latestVersion != null) {
          print('  ## ${_bold(package.changelog.latestVersion)}');
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
        print('Note - no changelog update for this change.');
      }
      if (package.pubspec.version.toString() !=
          package.changelog.latestVersion) {
        print("Note - pubspec version (${package.pubspec.version}) and "
            "changelog (${package.changelog.latestVersion})don't agree.");
      }

      if (Platform.environment.containsKey('PUB_CREDENTIALS')) {
        // Copy the pub oath information from the passed in environment variable
        // to a credentials file.
        var oathCredentials = Platform.environment['PUB_CREDENTIALS']!;
        var configDir = Directory(
          path.join(Platform.environment['HOME']!, '.config', 'dart'),
        );
        var credentialsFile = File(
          path.join(configDir.path, 'pub-credentials.json'),
        );
        credentialsFile.writeAsStringSync(oathCredentials);

        print('dart pub publish --force');
        var process = await Process.start(
          'dart',
          ['pub', 'publish', '--force'],
          workingDirectory: package.directory.path,
        );

        process.stdout
            .transform(utf8.decoder)
            .transform(LineSplitter())
            .listen((line) => stdout.writeln('  $line'));
        process.stderr
            .transform(utf8.decoder)
            .transform(LineSplitter())
            .listen((line) => stderr.writeln('  $line'));

        var code = await process.exitCode;
        if (code != 0) {
          io.exitCode = code;
        }
      } else {
        _failure('PUB_CREDENTIALS env variable not found; unable to publish.');
      }
    }
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
    io.exitCode = 1;
  }

  String _bold(String? message) {
    return '\u001b[1m$message\u001b[0m';
  }
}
