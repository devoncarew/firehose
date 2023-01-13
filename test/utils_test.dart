import 'package:firehose/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('Tag', () {
    test('invalid', () {
      var tag = Tag('1.2.4');
      expect(tag.valid, false);
    });

    test('invalid 2', () {
      var tag = Tag('v1.2');
      expect(tag.valid, false);
    });

    test('single package repo', () {
      var tag = Tag('v1.2.3');
      expect(tag.version, '1.2.3');
    });

    test('service release', () {
      var tag = Tag('v1.2.3+1');
      expect(tag.version, '1.2.3+1');
    });

    test('mono repo', () {
      var tag = Tag('foobar_v1.2.3');
      expect(tag.package, 'foobar');
      expect(tag.version, '1.2.3');
    });
  });
}
