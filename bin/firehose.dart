import 'dart:io';

import 'package:args/args.dart';
import 'package:firehose/firehose.dart';
import 'package:firehose/src/git.dart';

void main(List<String> arguments) {
  var argParser = _createArgs();
  try {
    var argResults = argParser.parse(arguments);

    if (argResults['help'] == true) {
      _usage(argParser);
      exit(0);
    }

    var verify = argResults['verify'] == true;
    var publish = argResults['publish'] == true;
    var verifyOrPublish = argResults['verify-or-publish'] == true;

    if (!verify && !publish && !verifyOrPublish) {
      _usage(argParser,
          error: 'Error: one of --verify, --publish, or --verify-or-publish '
              'must be specified.');
      exit(1);
    }

    var git = Git();
    if (publish && !git.inGithubContext) {
      _usage(argParser,
          error: 'Error: --publish can only be executed from within a GitHub '
              'action.');
      exit(1);
    }

    if (verifyOrPublish) {
      if (!git.inGithubContext || git.onGithubPR) {
        verify = true;
      } else {
        publish = true;
      }
    }

    var firehose = Firehose(Directory.current);
    if (verify) {
      firehose.verify();
    } else {
      firehose.publish();
    }
  } on ArgParserException catch (e) {
    _usage(argParser, error: e.message);
    exit(1);
  }
}

void _usage(ArgParser argParser, {String? error}) {
  if (error != null) {
    stderr.writeln(error);
    stderr.writeln();
  }

  print('usage: dart bin/firehose.dart <options>');
  print('');
  print(argParser.usage);
}

ArgParser _createArgs() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print tool help.',
    )
    ..addFlag(
      'verify',
      negatable: false,
      help: 'Validate any changes packages indicate whether --publish would '
          'publish anything.',
    )
    ..addFlag(
      'publish',
      negatable: false,
      help: 'Publish any changed packages.',
    )
    ..addFlag(
      'verify-or-publish',
      negatable: false,
      help:
          'Auto-detect the corrent behavior; on a PR, run --verify; on a merge '
          'into the default branch, run --publish.',
    );
}
