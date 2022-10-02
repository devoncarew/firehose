import 'package:firehose/src/git.dart';
import 'package:test/test.dart';

void main() {
  group('git', () {
    late Git git;

    setUp(() {
      git = Git();
    });

    test('commitCount', () {
      var count = git.commitCount;
      expect(count, greaterThan(0));
    });

    test('getChangedFiles', () {
      var result = git.getChangedFiles();
      expect(result, isNotEmpty);
    });
  });
}
