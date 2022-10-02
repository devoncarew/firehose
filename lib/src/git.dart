import 'dart:io';

import 'package:firehose/src/utils.dart';

// from a branch:
//   git.baseRef: main
//   git.headRef: update_branch_logic
//   git.ref: refs/pull/3/merge
//   git.refName: 3/merge

// from the default branch (after merging a PR):
//   git.baseRef:
//   git.headRef:
//   git.ref: refs/heads/main
//   git.refName: main

class Git {
  /// Whether we're running withing the context of a GitHub action.
  bool get inGithubContext {
    var token = Platform.environment['GITHUB_ACTIONS'];
    return token != null && token.isNotEmpty;
  }

  /// Whether we're being invoked in the context of a GitHub PR.
  bool get onGithubPR {
    return (baseRef?.isNotEmpty ?? false) && (headRef?.isNotEmpty ?? false);
  }

  /// Returns the number of git commits in the current branch.
  int get commitCount {
    var result = exec('git', args: ['rev-list', '--count', 'HEAD']);
    if (result.exitCode != 0) {
      return 0;
    }
    return int.tryParse(result.stdout.trim()) ?? 0;
  }

  // todo: get the commit count on the current branch
  // git rev-list --count HEAD

  /// The name of the event that triggered the workflow. For example,
  /// `workflow_dispatch`.
  String? get eventName {
    return Platform.environment['GITHUB_EVENT_NAME'];
  }

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

  /// The commit SHA that triggered the workflow. The value of this commit SHA
  /// depends on the event that triggered the workflow. For example,
  /// `ffac537e6cbbf934b08745a378932722df287a53`.
  String? get sha {
    return Platform.environment['GITHUB_SHA'];
  }

  /// Get the list of changed files for this PR or push to main.
  List<String> getChangedFiles({bool excludeTopLevelDotFiles = true}) {
    var result = exec(
      'git',
      args: ['diff', '--name-only', 'HEAD', 'HEAD~1'],
    );
    return result.stdout
        .split('\n')
        .where((str) => str.isNotEmpty)
        .where((path) {
      return excludeTopLevelDotFiles ? !path.startsWith('.') : true;
    }).toList();
  }
}
