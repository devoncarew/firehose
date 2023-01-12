import 'dart:io' hide exitCode;
import 'dart:io' as io show exitCode;

import 'package:firehose/src/repo.dart';

import 'src/git.dart';
import 'src/github.dart';
import 'src/utils.dart';

// todo: support allowing the glob of files to ignore to be configurable in the
// action configuration file (test/**, ...)

// todo: do we want to use the convention that pre-prelease pubspec versions are
// not published, or, use the convention that changes where the first changelog
// entry is 'unreleased' are not published? 'unreleased' is much clearer from
// the POV of knowing what's published or not when looking at the repo.

class Firehose {
  static const String _changelogExempt = 'changelog-exempt';

  final Directory directory;

  Firehose(this.directory);

  /// Verify the packages in the repository.
  void verify() async {
    // for a PR:
    //   - determine changed files
    //   - determine affected packages
    //   - validate that there's a changelog entry
    //   - validate that the changelog version == the pubspec version

    await _publish(dryRun: true);
  }

  /// Publish the changed packages in the repository.
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
    var github = Github();

    // TODO: validate that we can retrieve the git commit information here
    // (i.e., git.commitCount > 0)

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
      var repoTag = repo.calculateRepoTag(package);

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

      var labels = (env['PR_LABELS'] ?? '').split(',');
      var changelogExempt = labels.contains(_changelogExempt);

      // checks
      if (dryRun) {
        var issues = 0;

        if (!changelogUpdated) {
          if (changelogExempt) {
            print("No changelog update for this change (ignoring due to "
                "'$_changelogExempt').");
          } else {
            _failure('No changelog update for this change.');
            issues++;
          }
        }
        if (pubspecVersion != changelogVersion) {
          _failure("pubspec version ($pubspecVersion) and "
              "changelog ($changelogVersion)don't agree.");
          issues++;
        }

        if (issues == 0) {
          if (package.pubspec.isPreRelease) {
            var message =
                'Note - version ($pubspecVersion) is pre-release; package will '
                'not be auto-published.';

            print(message);
            github.appendStepSummary(package.name, message);
          } else {
            var message =
                "Once this change lands in the default branch, tagging "
                "the commit with '$repoTag' will trigger a publish.";

            print('No issues found.\n$message');
            github.appendStepSummary(package.name, message);

            if (package.pubspec.versionLine != null) {
              github.emitFileNoticeMarker(
                file: package.pubspec.localFilePath,
                line: package.pubspec.versionLine!,
                title: 'Auto publish',
                message: message,
              );
            }
          }
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
        } else if (package.pubspec.isPreRelease) {
          print('version ($pubspecVersion) is pre-release; package will not be '
              'auto-published.');
        } else {
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
            var result = await stream('git', args: ['tag', repoTag]);
            if (result != 0) {
              io.exitCode = code;
            } else {
              // And push it upstream.
              result = await stream('git', args: ['push', 'origin', repoTag]);
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
