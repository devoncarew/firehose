import 'package:firehose/firehose.dart' as firehose;
import 'package:firehose/src/git.dart';

// for a PR:
// - determine changed files
// - determine affected packages
// - validate that there's a changelog entry
// - validate that the changelog version == the pubspec version
// - validate that the pubspec version != a published version

// for the default branch:
// - determine changed files
// - determine affected packages
// - validate that the pubspec version != a published version
// - attempt to publish

// todo: support args (and help)

// todo: parse changelog version

// todo: determine paths changed from the current commit

// todo: determine paths changed from the current PR

// --verify, --publish, --verify-or-publish

void main(List<String> arguments) {
  print('Hello world: ${firehose.calculate()}!');

  var git = Git();
  print('git.baseRef: ${git.baseRef}');
  print('git.headRef: ${git.headRef}');
  print('git.ref: ${git.ref}');
  print('git.refName: ${git.refName}');

  print('');
  print('commit changed files:');
  for (var file in git.getCommitChangedFiles()) {
    print('  $file');
  }

  print('');
  print('PR changed files:');
  for (var file in git.getPRChangedFiles()) {
    print('  $file');
  }
}
