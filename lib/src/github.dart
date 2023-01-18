import 'dart:io';

class Github {
  /// Write the given [markdownSummary] content to the GitHub
  /// `GITHUB_STEP_SUMMARY` file. This will cause the markdown output to be
  /// appended to the GitHub job summary for the current PR.
  void appendStepSummary(String title, String markdownSummary) {
    var summaryPath = Platform.environment['GITHUB_STEP_SUMMARY'];
    if (summaryPath == null) {
      stderr.writeln("'GITHUB_STEP_SUMMARY' doesn't exist.");
      return;
    }

    var output = '## $title\n\n$markdownSummary\n';

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
}
