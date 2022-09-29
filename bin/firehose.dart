import 'package:firehose/firehose.dart' as firehose;
import 'package:firehose/src/git.dart';

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
}
