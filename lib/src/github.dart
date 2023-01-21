import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class Github {
  String? get _githubAuthToken => _env['GITHUB_TOKEN'];

  http.Client? _httpClient;

  http.Client get httpClient => (_httpClient ??= http.Client());

  void close() {
    _httpClient?.close();
  }

  static Map<String, String> get _env => Platform.environment;

  String? get repoSlug => _env['GITHUB_REPOSITORY'];

  String? get issueNumber => _env['ISSUE_NUMBER'];

  String? get sha => _env['GITHUB_SHA'];

  /// Write the given [markdownSummary] content to the GitHub
  /// `GITHUB_STEP_SUMMARY` file. This will cause the markdown output to be
  /// appended to the GitHub job summary for the current PR.
  void appendStepSummary(String title, String markdownSummary) {
    var summaryPath = _env['GITHUB_STEP_SUMMARY'];
    if (summaryPath == null) {
      stderr.writeln("'GITHUB_STEP_SUMMARY' doesn't exist.");
      return;
    }

    var output = '### $title\n\n$markdownSummary\n';

    var file = File(summaryPath);
    file.writeAsStringSync(output, mode: FileMode.append);
  }

  /// Add a GitHub notice marker to the given file and line. This must be called
  /// in the content of a GitHub action job.
  void emitFileNoticeMarker({
    required String file,
    required int line,
    required String message,
  }) {
    // ::notice file={name},line={line},endLine={endLine},title={title}::{message}
    print('::notice file=$file,line=$line::$message');
  }

  Future<String> callRestApi(Uri uri) async {
    var token = _githubAuthToken!;

    return httpClient.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/vnd.github+json',
    }).then((response) {
      return response.statusCode != 200
          ? throw response.reasonPhrase!
          : response.body;
    });
  }

  Future<String> callRestApiPost(Uri uri, String body) async {
    var token = _githubAuthToken!;

    return httpClient
        .post(uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/vnd.github+json',
            },
            body: body)
        .then((response) {
      return response.statusCode != 201
          ? throw response.reasonPhrase!
          : response.body;
    });
  }

  Future<String> callRestApiPatch(Uri uri, String body) async {
    var token = _githubAuthToken!;

    return httpClient
        .patch(uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/vnd.github+json',
            },
            body: body)
        .then((response) {
      return response.statusCode != 200
          ? throw response.reasonPhrase!
          : response.body;
    });
  }

  Future<String> createComment(
      String repoSlug, String issueNumber, String commentText) async {
    String org = repoSlug.split('/')[0];
    String repo = repoSlug.split('/')[1];

    var result = await callRestApiPost(
      Uri.parse(
          'https://api.github.com/repos/$org/$repo/issues/$issueNumber/comments'),
      jsonEncode({'body': commentText}),
    );
    var json = jsonDecode(result) as Map;
    return json['url'];
  }

  Future<int?> findCommentId(
    String repoSlug,
    String issueNumber, {
    required String user,
    String? searchTerm,
  }) async {
    String org = repoSlug.split('/')[0];
    String repo = repoSlug.split('/')[1];

    var result = await callRestApi(
      Uri.parse('https://api.github.com/repos/$org/$repo/issues/$issueNumber/'
          'comments?per_page=100'),
    );

    var items = jsonDecode(result) as List;
    for (var item in items) {
      item as Map;
      var id = item['id'] as int;
      var userLogin = item['user']['login'] as String;
      var body = item['body'] as String;

      print('comment: $id, user: $userLogin');

      if (userLogin != user) continue;

      if (searchTerm != null && !body.contains(searchTerm)) continue;

      return id;
    }

    return null;
  }

  Future<String> updateComment(
      String repoSlug, int commentId, String commentText) async {
    String org = repoSlug.split('/')[0];
    String repo = repoSlug.split('/')[1];

    var result = await callRestApiPatch(
      Uri.parse(
          'https://api.github.com/repos/$org/$repo/issues/comments/$commentId'),
      jsonEncode({'body': commentText}),
    );
    var json = jsonDecode(result) as Map;
    return json['url'];
  }

  // create a check run
  // POST /repos/{owner}/{repo}/check-runs
  // [status] is one of queued, in_progress, completed
  Future<int> createCheckRun(
    String repoSlug, {
    required String name,
    required String sha,
    required String status,
    required String outputTitle,
    required String outputSummary,
  }) async {
    String org = repoSlug.split('/')[0];
    String repo = repoSlug.split('/')[1];

    var result = await callRestApiPost(
      Uri.parse('https://api.github.com/repos/$org/$repo/check-runs'),
      jsonEncode({
        'name': name,
        'head_sha': sha,
        'status': status,
        'output': {
          'title': outputTitle,
          'summary': outputSummary,
        },
      }),
    );
    var json = jsonDecode(result) as Map;
    return json['id'] as int;
  }

  // update a check run
  // PATCH /repos/{owner}/{repo}/check-runs/{check_run_id}
  // [conclusion] can be one of action_required, cancelled, failure, neutral,
  // success, skipped, stale, timed_out
  Future updateCheckRun(
    String repoSlug,
    int checkRunId, {
    required String conclusion,
    required String outputTitle,
    required String outputSummary,
  }) async {
    String org = repoSlug.split('/')[0];
    String repo = repoSlug.split('/')[1];

    var result = await callRestApiPatch(
      Uri.parse(
          'https://api.github.com/repos/$org/$repo/check-runs/$checkRunId'),
      jsonEncode({
        'conclusion': conclusion,
        'output': {
          'title': outputTitle,
          'summary': outputSummary,
        },
      }),
    );
    // ignore: unused_local_variable
    var json = jsonDecode(result) as Map;
  }
}
