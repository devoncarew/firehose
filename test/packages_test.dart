import 'package:firehose/src/packages.dart';
import 'package:test/test.dart';

void main() {
  group('packages', () {
    late Packages packages;

    setUp(() {
      packages = Packages();
    });

    test('locatePackages', () {
      var result = packages.locatePackages();

      expect(result, isNotEmpty);
      // test a property of our specific package
      expect(result.first.publishingEnabled, true);
    });
  });
}
