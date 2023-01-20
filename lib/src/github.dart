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

  static Map<String, String> get _env => _env;

  String? get repoSlug => _env['GITHUB_ACTION_REPOSITORY'];

  String? get issueNumber => _env['ISSUE_NUMBER'];

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

  // Future<String?> callRestApi(Uri uri) async {
  //   var token = _githubAuthToken!;

  //   return httpClient.get(uri, headers: {
  //     'Authorization': 'Bearer $token',
  //     'Accept': 'application/vnd.github+json',
  //   }).then((response) {
  //     return response.statusCode == 404 ? null : response.body;
  //   });
  // }

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
}
