import 'dart:io';

import 'utils.dart';

class Git {
  /// Return the name of the current branch.
  ///
  /// Returns null when run in a location not under source control.
  String? get currentBranch {
    var branchName = Platform.environment['GITHUB_REF_NAME'];
    if (branchName != null) {
      return branchName;
    }

    var results = exec('git', args: ['branch', '--show-current']);
    if (results.exitCode != 0) {
      return null;
    }

    branchName = results.stdout.split('\n').first.trim();
    return branchName.isEmpty ? null : branchName;
  }
}
