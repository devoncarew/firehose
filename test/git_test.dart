import 'package:firehose/src/git.dart';
import 'package:test/test.dart';

void main() {
  group('git', () {
    late Git git;

    setUp(() {
      git = Git();
    });

    test('currentBranch', () {
      var branch = git.currentBranch;
      print('branch name: $branch');
      expect(branch, isNotNull);
    });
  });
}
