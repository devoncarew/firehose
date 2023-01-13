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
/// This will also echo the command being run to stdout and indent the processes
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

class Tag {
  static final RegExp packageVersionTag =
      RegExp(r'(\S+)_v(\d+\.\d+\.\d+(\+.*)?)');

  static final RegExp packageTag = RegExp(r'v(\d+\.\d+\.\d+(\+.*)?)');

  final String tag;

  Tag(this.tag);

  bool get valid => version != null;

  String? get package {
    var match = packageVersionTag.firstMatch(tag);
    return match?.group(1);
  }

  String? get version {
    var match = packageVersionTag.firstMatch(tag);
    if (match != null) {
      return match.group(2);
    }
    match = packageTag.firstMatch(tag);
    return match?.group(1);
  }
}
