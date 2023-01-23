import 'dart:io';

import 'package:collection/collection.dart';
import 'package:firehose/src/repo.dart';

import 'src/github.dart';
import 'src/pub.dart';
import 'src/utils.dart';

const String _dependabotUser = 'dependabot[bot]';

const String _githubActionsUser = 'github-actions[bot]';

const String _publishBotTag = '**publish bot**';

class Firehose {
  final Directory directory;

  Firehose(this.directory);

  /// Verify the packages in the repository.
  Future verify() async {
    var github = Github();

    if (github.actor == _dependabotUser) {
      print('Skipping package validation for dependabot PR.');
      return;
    }

    // for a PR:
    //   - determine packages
    //   - validate that the changelog version == the pubspec version

    var results = await _verify(github);

    var existingCommentId = await github.findCommentId(
        github.repoSlug!, github.issueNumber!,
        user: _githubActionsUser, searchTerm: _publishBotTag);

    if (existingCommentId != null || results.hasSuccess) {
      var text = '$_publishBotTag:\n\n${results.describe}';

      if (existingCommentId == null) {
        await github.createComment(github.repoSlug!, github.issueNumber!, text);
      } else {
        await github.updateComment(github.repoSlug!, existingCommentId, text);
      }
    }

    github.close();
  }

  Future<VerificationResults> _verify(Github github) async {
    var repo = Repo();
    var packages = repo.locatePackages();

    var pub = Pub();

    var results = VerificationResults();

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
        var result = Result.fail(
          package,
          'pubspec version ($pubspecVersion) and changelog ($changelogVersion) '
          "don't agree.",
        );
        print(result);
        results.addResult(result);
        continue;
      }

      if (await pub.hasPublishedVersion(package.name, pubspecVersion!)) {
        var result = Result.info(
            package, '$pubspecVersion already published at pub.dev.');
        print(result);
        results.addResult(result);
      } else if (package.pubspec.isPreRelease) {
        var result = Result.info(
          package,
          'version ($pubspecVersion) is pre-release; no publish is '
          'necessary.',
        );
        print(result);
        results.addResult(result);
      } else {
        var code = await stream('dart',
            args: ['pub', 'publish', '--dry-run'], cwd: package.directory);
        if (code != 0) {
          exitCode = code;
          results
              .addResult(Result.fail(package, 'Pub publish dry-run failed.'));
        } else {
          var message =
              'After merging, tag with $repoTag to trigger a publish.';
          print('No issues found.\n$message');

          // "**publish bot**: package:firehose \@ 0.3.7 is ready to publish.
          // After merging, tag with `v0.3.7` to trigger a publish.""
          var result = Result.success(
              package,
              'package:${package.name} \\@ '
              '${package.pubspec.version} is ready to publish. After merging, '
              'tag with `$repoTag` to trigger a publish.');
          print(result);
          results.addResult(result);
        }
      }
    }

    pub.close();

    return results;
  }

  /// Publish the indicated package in the repository.
  Future publish() async {
    // for tagged commits:
    //   - validate the tag
    //   - validate the package exists
    //   - validate changelog and pubspec versions
    //   - publish

    var success = await _publish();
    if (!success && exitCode == 0) {
      exitCode = 1;
    }
  }

  Future<bool> _publish() async {
    var github = Github();

    // Validate the git tag.
    if (github.refName == null) {
      stderr.writeln('Git tag not found.');
      return false;
    }
    var tag = Tag(github.refName!);
    if (!tag.valid) {
      stderr.writeln("Git tag not in expected format: '$tag'");
      return false;
    }

    print("Publishing '$tag'");
    print('');

    var repo = Repo();
    var packages = repo.locatePackages();
    print('');
    print('Repository packages:');
    for (var package in packages) {
      print('  $package');
    }
    print('');

    // Find package to publish.
    Package? package;
    if (repo.singlePackageRepo) {
      if (packages.isEmpty) {
        stderr.writeln('No publishable package found.');
        return false;
      }
      package = packages.first;
    } else {
      var name = tag.package;
      if (name == null) {
        stderr.writeln("Tag does not include package name ('$tag').");
        return false;
      }
      package = packages.firstWhereOrNull((p) => p.name == name);
      if (package == null) {
        stderr.writeln("Tag does not match a repo package ('$tag').");
        return false;
      }
    }

    print('');
    print('Publishing ${_bold('package:${package.name}')}');
    print('');

    print('pubspec:');
    var pubspecVersion = package.pubspec.version;
    print('  version: ${_bold(pubspecVersion)}');

    print('changelog:');
    print(package.changelog.describeLatestChanges);
    var changelogVersion = package.changelog.latestVersion;

    if (pubspecVersion != tag.version) {
      stderr.writeln(
          "Pubspec version ($pubspecVersion) and git tag ($tag) don't agree.");
      return false;
    }

    if (pubspecVersion != changelogVersion) {
      stderr.writeln('Pubspec version ($pubspecVersion) and changelog version '
          "($changelogVersion) don't agree.");
      return false;
    }

    await stream('dart', args: ['pub', 'get'], cwd: package.directory);
    print('');

    var result = await stream('dart',
        args: ['pub', 'publish', '--force'], cwd: package.directory);
    if (result != 0) {
      exitCode = result;
    }
    return result == 0;
  }

  String _bold(String? message) {
    return '\u001b[1m$message\u001b[0m';
  }

  Map<String, String> get env => Platform.environment;
}

class VerificationResults {
  final List<Result> results = [];

  void addResult(Result result) => results.add(result);

  bool get hasSuccess => results.any((r) => r.severity == Severity.success);

  String get describe {
    // var githubMessage = '$_publishBotTag: package:${package.name} \\@ '
    //     '${package.pubspec.version} is ready to publish. After merging, '
    //     'tag with `$repoTag` to trigger a publish.';

    return results.map((r) {
      var sev = r.severity == Severity.error ? '(error) ' : '';
      return '- ${r.package.name}: $sev${r.message}';
    }).join('\n');
  }
}

class Result {
  final Severity severity;
  final Package package;
  final String message;

  Result(this.severity, this.package, this.message);

  factory Result.fail(Package package, String message) =>
      Result(Severity.error, package, message);

  factory Result.info(Package package, String message) =>
      Result(Severity.info, package, message);

  factory Result.success(Package package, String message) =>
      Result(Severity.success, package, message);

  @override
  String toString() => message;
}

enum Severity {
  error,
  info,
  success;
}
