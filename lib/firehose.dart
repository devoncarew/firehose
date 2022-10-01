import 'dart:io';

import 'src/changelog.dart';
import 'src/git.dart';

class Firehose {
  final Directory directory;

  Firehose(this.directory);

  void verify() {
    // todo:
    print('todo: verify');
    print('');
    scratch();
  }

  void publish() {
    // todo:
    print('todo: publish');
    print('');
    scratch();
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
