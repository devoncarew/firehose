import 'package:firehose/firehose.dart' as firehose;

// todo: support args (and help)

// todo: parse changelog version

// todo: determine paths changed from the current commit

// todo: determine paths changed from the current PR

// --verify, --publish, --verify-or-publish

void main(List<String> arguments) {
  print('Hello world: ${firehose.calculate()}!');
}
