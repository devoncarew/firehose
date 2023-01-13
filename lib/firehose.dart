import 'dart:io' hide exitCode;
import 'dart:io' as io show exitCode;

import 'package:collection/collection.dart';
import 'package:firehose/src/repo.dart';

import 'src/git.dart';
import 'src/github.dart';
import 'src/utils.dart';

// TODO: support allowing the glob of files to ignore to be configurable in the
// action configuration file (test/**, ...)

class Firehose {
  static const String _changelogExempt = 'changelog-exempt';

  final Directory directory;

  Firehose(this.directory);

  /// Verify the packages in the repository.
  Future verify() async {
    // for a PR:
    //   - determine changed files
    //   - determine affected packages
    //   - validate that there's a changelog entry
    //   - validate that the changelog version == the pubspec version

    try {
      await _verify();
    } on _Fail {
      if (io.exitCode == 0) {
        io.exitCode = 1;
      }
    }
  }

  /// Publish the changed packages in the repository.
  Future publish() async {
    // for tagged commits:
    //   - validate the tag
    //   - validate the package exists
    //   - validate changelog and pubspec versions
    //   - publish

    try {
      await _publish();
    } on _Fail {
      if (io.exitCode == 0) {
        io.exitCode = 1;
      }
    }
  }

  Future<void> _verify() async {
    var git = Git();
    var github = Github();

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
      print('Validating ${_bold('package:${package.name}')}');

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
        print(package.changelog.describeLatestChanges);
      }

      print('changed files:');
      for (var file in packageChangesFiles) {
        print('  $file');
      }

      var labels = (env['PR_LABELS'] ?? '').split(',');
      var changelogExempt = labels.contains(_changelogExempt);

      // checks
      if (!changelogUpdated) {
        if (changelogExempt) {
          print("No changelog update for this change (ignoring due to "
              "'$_changelogExempt').");
        } else {
          _fail("No changelog update for this change. If you believe this "
              "PR is exempt, add the '$_changelogExempt' label to skip the "
              "changelog check.");
        }
      }
      if (pubspecVersion != changelogVersion) {
        _fail("pubspec version ($pubspecVersion) and changelog "
            "($changelogVersion) don't agree.");
      }

      if (package.pubspec.isPreRelease) {
        var message =
            'Note - version ($pubspecVersion) is pre-release; package will '
            'not be auto-published.';

        print(message);
        github.appendStepSummary('package:${package.name}', message);
      } else {
        var message =
            "After merging, tag with '$repoTag' to trigger a publish.";

        print('No issues found.\n$message');
        github.appendStepSummary(
          'package:${package.name}',
          '$message\n\n${package.changelog.describeLatestChanges}',
        );

        if (package.pubspec.versionLine != null) {
          github.emitFileNoticeMarker(
            file: package.pubspec.localFilePath,
            line: package.pubspec.versionLine!,
            message: message,
          );
        }
      }
    }
  }

  Future<void> _publish() async {
    var git = Git();

    // Validate the git tag.
    var tag = git.refName;
    if (tag == null) {
      _fail('Git tag not found.');
    }
    var parsedTag = Tag(tag);
    if (!parsedTag.valid) {
      _fail("Git tag not in expected format: '$tag'");
    }

    var repo = Repo();
    var packages = repo.locatePackages();
    print('');
    print('Repository publishable packages:');
    for (var package in packages) {
      print('  $package');
    }

    // Find package to publish.
    Package? package;
    if (repo.singlePackageRepo) {
      if (packages.isEmpty) {
        _fail('No publishable package found.');
      }
      package = packages.first;
    } else {
      var name = parsedTag.package;
      if (name == null) {
        _fail("Tag does not include package name ('$tag').");
      }
      package = packages.firstWhereOrNull((p) => p.name == name);
      if (package == null) {
        _fail("Tag does not match a repo package ('$tag').");
      }
    }

    print('');
    print('Publishing ${_bold('package:${package.name}')}');

    print('pubspec:');
    var pubspecVersion = package.pubspec.version;
    print('  version: ${_bold(pubspecVersion)}');
    if (package.pubspec.autoPublishValue != null) {
      print('  auto_publish: ${package.pubspec.autoPublishValue}');
    }
    if (package.pubspec.publishToValue != null) {
      print('  publish_to: ${package.pubspec.publishToValue}');
    }

    print('changelog:');
    print(package.changelog.describeLatestChanges);
    var changelogVersion = package.changelog.latestVersion;

    if (pubspecVersion != parsedTag.version) {
      _fail(
          "Pubspec version ($pubspecVersion) and git tag ($tag) don't agree.");
    }

    if (pubspecVersion != changelogVersion) {
      _fail("Pubspec version ($pubspecVersion) and changelog version "
          "($changelogVersion) don't agree.");
    }

    var result = await stream(
      'dart',
      args: ['pub', 'get'],
      cwd: package.directory,
    );
    if (result != 0) {
      io.exitCode = result;
    }

    var code = await stream(
      'dart',
      args: ['pub', 'publish', '--force'],
      cwd: package.directory,
    );
    if (code != 0) {
      io.exitCode = code;
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

  Never _fail(String message) {
    print('\u001b[31merror: $message\u001b[0m');
    throw _Fail();
  }

  String _bold(String? message) {
    return '\u001b[1m$message\u001b[0m';
  }

  Map<String, String> get env => Platform.environment;
}

class _Fail implements Exception {}
