import 'package:firehose/src/repo.dart';
import 'package:test/test.dart';

void main() {
  group('repo', () {
    late Repo packages;

    setUp(() {
      packages = Repo();
    });

    test('singlePackageRepo', () {
      var result = packages.singlePackageRepo;
      expect(result, true);
    });

    test('locatePackages', () {
      var result = packages.locatePackages();

      expect(result, isNotEmpty);
    });
  });
}
