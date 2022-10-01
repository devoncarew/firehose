import 'dart:io';

class ExecResults {
  final int exitCode;
  final String stdout;
  final String stderr;

  ExecResults({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });
}

/// Execute the given CLI command and return the results (exit code, stdout, and
/// stderr).
ExecResults exec(
  String command, {
  List<String> args = const [],
  Directory? cwd,
  Map<String, String>? env,
}) {
  var result = Process.runSync(
    command,
    args,
    workingDirectory: cwd?.path,
    environment: env,
  );
  return ExecResults(
    exitCode: result.exitCode,
    stdout: result.stdout,
    stderr: result.stderr,
  );
}
