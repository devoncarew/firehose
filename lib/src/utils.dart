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

ExecResults exec(
  String command, {
  List<String> args = const [],
  Directory? cwd,
}) {
  // todo:
  print('[$command ${args.join(', ')}]');

  var result = Process.runSync(command, args, workingDirectory: cwd?.path);
  return ExecResults(
    exitCode: result.exitCode,
    stdout: result.stdout,
    stderr: result.stderr,
  );
}
