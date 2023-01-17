import 'dart:io';

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
}
