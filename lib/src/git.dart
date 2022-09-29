import 'utils.dart';

class Git {
  /// Return the name of the current branch.
  ///
  /// Returns null when run in a location not under source control.
  String? get currentBranch {
    var results = exec('git', args: ['branch', '--show-current']);
    if (results.exitCode != 0) {
      return null;
    }
    String branch = results.stdout.split('\n').first.trim();
    return branch.isEmpty ? null : branch;
  }
}
