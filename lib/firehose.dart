import 'dart:io' hide exitCode;
import 'dart:io' as io show exitCode;

import 'package:firehose/src/repo.dart';
import 'package:path/path.dart' as path;

import 'src/git.dart';
import 'src/utils.dart';

// todo: support allowing the glob of files to ignore to be configurable in the
// action configuration file (test/**, ...)

class Firehose {
  final Directory directory;

  Firehose(this.directory);

  void verify() async {
    // for a PR:
    //   - determine changed files
    //   - determine affected packages
    //   - validate that there's a changelog entry
    //   - validate that the changelog version == the pubspec version

    await _publish(dryRun: true);
  }

  void publish() async {
    // for the default branch:
    //   - determine changed files
    //   - determine affected packages
    //   - attempt to publish
    //   - tag the commit

    await _publish(dryRun: false);
  }

  Future<void> _publish({required bool dryRun}) async {
    var git = Git();

    var changedFiles = git.getChangedFiles();
    print('Repository changed files:');
    for (var file in changedFiles) {
      print('- $file');
    }

    var repo = Repo();
    var packages = repo.locatePackages();
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
      var actionDescription = dryRun ? 'Validating' : 'Publishing';
      print('$actionDescription ${_bold('package:${package.name}')}');

      print('pubspec:');
      var pubspecVersion = package.pubspec.version;
      print('  version: ${_bold(pubspecVersion)}');
      if (package.pubspec.autoPublishValue != null) {
        print('  auto_publish: ${package.pubspec.autoPublishValue}');
      }
      if (package.pubspec.publishToValue != null) {
        print('  publish_to: ${package.pubspec.publishToValue}');
      }

      var packageChangesFiles = package.matchingFiles(changedFiles);

      var changelogUpdated = packageChangesFiles.contains('CHANGELOG.md');
      var changelogVersion = package.changelog.latestVersion;
      if (changelogUpdated) {
        print('changelog:');
        if (changelogVersion != null) {
          print('  ## ${_bold(changelogVersion)}');
        }
        for (var entry in package.changelog.latestChangeEntries) {
          print('  $entry');
        }
      }

      print('changed files:');
      for (var file in packageChangesFiles) {
        print('  $file');
      }

      var labels = <String>[];
      if (env.containsKey('PR_LABELS')) {
        labels = env['PR_LABELS']!.split('.');
      }
      var changelogExempt = labels.contains('changelog-exempt');

      // checks
      if (dryRun) {
        var issues = 0;
        if (!changelogUpdated) {
          if (changelogExempt) {
            print("No changelog update for this change (ignoring due to "
                "'changelog-exempt').");
          } else {
            _failure('No changelog update for this change.');
            issues++;
          }
        }
        if (pubspecVersion != changelogVersion) {
          issues++;
          _failure("pubspec version ($pubspecVersion) and "
              "changelog ($changelogVersion)don't agree.");
        }
        if (issues == 0) {
          print('No issues found.');
        }
      } else {
        if (!changelogUpdated) {
          print('Note - no changelog update for this change.');
        }
        if (pubspecVersion != changelogVersion) {
          print("Note - pubspec version ($pubspecVersion) and "
              "changelog ($changelogVersion)don't agree.");
        }
      }

      if (!dryRun) {
        if (!packageChangesFiles.contains('pubspec.yaml')) {
          print('pubspec.yaml not changed; not attempting to publish.');
        } else if (!env.containsKey('PUB_CREDENTIALS')) {
          _failure(
              'PUB_CREDENTIALS env variable not found; unable to publish.');
        } else {
          // Copy the pub oath information from the passed in environment
          // variable to a credentials file.
          var oathCredentials = env['PUB_CREDENTIALS']!;
          var configDir = Directory(
            path.join(env['HOME']!, '.config', 'dart'),
          );
          configDir.createSync(recursive: true);
          var credentialsFile = File(
            path.join(configDir.path, 'pub-credentials.json'),
          );
          credentialsFile.writeAsStringSync(oathCredentials);

          var code = await stream(
            'dart',
            args: ['pub', 'publish', '--force'],
            cwd: package.directory,
          );
          if (code != 0) {
            io.exitCode = code;
          } else {
            // Publishing was successful; tag the commit and push it upstream.

            // Tag with either <version> or <package>-v<version>.
            String tag;
            if (repo.singlePackageRepo) {
              tag = pubspecVersion!;
            } else {
              tag = '${package.name}-v$pubspecVersion';
            }

            // Tag the commit.
            var result = await stream('git', args: ['tag', tag]);
            if (result != 0) {
              io.exitCode = code;
            } else {
              // And push it upstream.
              result = await stream('git', args: ['push', 'origin', tag]);
              if (result != 0) {
                io.exitCode = code;
              }
            }
          }
        }
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

  Map<String, String> get env => Platform.environment;
}
