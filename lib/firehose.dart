import 'dart:io' hide exitCode;
import 'dart:io' as io show exitCode;

import 'package:collection/collection.dart';
import 'package:firehose/src/repo.dart';

import 'src/git.dart';
import 'src/github.dart';
import 'src/pub.dart';
import 'src/utils.dart';

// todo: create a results object

class Firehose {
  final Directory directory;

  Firehose(this.directory);

  /// Verify the packages in the repository.
  Future verify() async {
    // for a PR:
    //   - determine packages
    //   - validate that the changelog version == the pubspec version

    try {
      await _verify();
    } on _Fail {
      if (io.exitCode == 0) {
        io.exitCode = 1;
      }
    }
  }

  /// Publish the indicated package in the repository.
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
    var github = Github();
    var repo = Repo();
    var pub = Pub();
    var packages = repo.locatePackages();

    // var checkRunId = await github.createCheckRun(
    //   github.repoSlug!,
    //   name: 'publishing',
    //   sha: github.sha!,
    //   status: 'in_progress',
    //   outputTitle: 'Publishing checks',
    //   outputSummary: 'Checks in progress.',
    // );

    var existingCommentId = await github.findCommentId(
        github.repoSlug!, github.issueNumber!,
        user: 'github-actions[bot]', searchTerm: '**publish bot**:');

    print('existingCommentId=$existingCommentId');

    for (var package in packages) {
      var repoTag = repo.calculateRepoTag(package);

      print('');
      print('Validating ${_bold('package:${package.name}')}');

      print('pubspec:');
      var pubspecVersion = package.pubspec.version;
      print('  pubspec version: ${_bold(pubspecVersion)}');

      var changelogVersion = package.changelog.latestVersion;
      print('changelog:');
      print(package.changelog.describeLatestChanges.trimRight());

      print('');

      if (pubspecVersion != changelogVersion) {
        _fail("pubspec version ($pubspecVersion) and changelog "
            "($changelogVersion) don't agree.");
      }

      if (await pub.hasPublishedVersion(package.name, pubspecVersion!)) {
        print('$pubspecVersion already published at pub.dev.');
      } else if (package.pubspec.isPreRelease) {
        print('Note - version ($pubspecVersion) is pre-release; package will '
            'not be auto-published.');
      } else {
        var code = await stream('dart',
            args: ['pub', 'publish', '--dry-run'], cwd: package.directory);
        if (code != 0) io.exitCode = code;

        if (code == 0) {
          var message =
              'After merging, tag with $repoTag to trigger a publish.';
          print('No issues found.\n$message');

          github.appendStepSummary('package:${package.name}', message);

          // "**publish bot**: package:firehose \@ 0.3.7 is ready to publish.
          // After merging, tag with `v0.3.7` to trigger a publish.""
          var githubMessage =
              '**publish bot**: package:${package.name} \\@ ${package.version} '
              'is ready to publish. After merging, tag with `$repoTag` to '
              'trigger a publish.';

          if (existingCommentId == null) {
            var result = await github.createComment(
              github.repoSlug!,
              github.issueNumber!,
              githubMessage,
            );
            print(result);
          } else {
            var result = await github.updateComment(
              github.repoSlug!,
              existingCommentId,
              githubMessage,
            );
            print(result);
          }

          // // todo: create the checks at the end...
          // await github.updateCheckRun(
          //   github.repoSlug!,
          //   checkRunId,
          //   conclusion: 'success',
          //   outputTitle: 'Publishing checks',
          //   outputSummary: 'package:${package.name} \\@ ${package.version} is '
          //       'ready to publish. After merging, tag with `$repoTag` to '
          //       'trigger a publish.',
          // );
        }
      }
    }

    github.close();
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

    var result =
        await stream('dart', args: ['pub', 'get'], cwd: package.directory);
    if (result != 0) io.exitCode = result;

    var code = await stream('dart',
        args: ['pub', 'publish', '--force'], cwd: package.directory);
    if (code != 0) io.exitCode = code;
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
