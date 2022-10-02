import 'dart:convert';
import 'dart:io';

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

/// Execute the given CLI command asynchronously, streaming stdout and stderr to
/// the console.
///
/// This will also echo the command being to stdout, and indent the processes
/// output slightly.
Future<int> stream(
  String command, {
  List<String> args = const [],
  Directory? cwd,
}) async {
  print('$command ${args.join(' ')}');

  var process = await Process.start(
    command,
    args,
    workingDirectory: cwd?.path,
  );

  process.stdout
      .transform(utf8.decoder)
      .transform(LineSplitter())
      .listen((line) => stdout.writeln('  $line'));
  process.stderr
      .transform(utf8.decoder)
      .transform(LineSplitter())
      .listen((line) => stderr.writeln('  $line'));

  return process.exitCode;
}
