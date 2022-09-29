import 'dart:io';

import 'package:path/path.dart' as path;

class Git {
  /// The name of the base ref or target branch of the pull request in a
  /// workflow run. This is only set when the event that triggers a workflow run
  /// is either pull_request or pull_request_target. For example, `main`.
  String? get baseRef {
    return Platform.environment['GITHUB_BASE_REF'];
  }

  /// The head ref or source branch of the pull request in a workflow run. This
  /// property is only set when the event that triggers a workflow run is either
  /// pull_request or pull_request_target. For example, `feature-branch-1`.
  String? get headRef {
    return Platform.environment['GITHUB_HEAD_REF'];
  }

  /// The fully-formed ref of the branch or tag that triggered the workflow run.
  /// For workflows triggered by push, this is the branch or tag ref that was
  /// pushed. For workflows triggered by pull_request, this is the pull request
  /// merge branch. For workflows triggered by release, this is the release tag
  /// created. For other triggers, this is the branch or tag ref that triggered
  /// the workflow run. This is only set if a branch or tag is available for the
  /// event type. The ref given is fully-formed, meaning that for branches the
  /// format is refs/heads/<branch_name>, for pull requests it is
  /// refs/pull/<pr_number>/merge, and for tags it is refs/tags/<tag_name>. For
  /// example, `refs/heads/feature-branch-1`.
  String? get ref {
    return Platform.environment['GITHUB_REF'];
  }

  /// The short ref name of the branch or tag that triggered the workflow run.
  /// This value matches the branch or tag name shown on GitHub. For example,
  /// `feature-branch-1`.
  String? get refName {
    return Platform.environment['GITHUB_REF_NAME'];
  }

  /// Return the name of the current branch.
  ///
  /// Returns null when run in a location not under source control.
  String? get currentBranch {
    // var branchName = Platform.environment['GITHUB_HEAD_REF'];
    // if (branchName != null) {
    //   return branchName;
    // }

    // .git/HEAD
    var headFile = File(path.join('.git', 'HEAD'));
    if (!headFile.existsSync()) {
      return null;
    }

    // ref: refs/heads/main
    var line = headFile.readAsLinesSync().first;
    return line.split('/').last;

    // var results = exec('git', args: ['branch', '--show-current']);
    // if (results.exitCode != 0) {
    //   return null;
    // }

    // branchName = results.stdout.split('\n').first.trim();
    // return branchName.isEmpty ? null : branchName;
  }
}
