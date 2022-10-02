[![Dart](https://github.com/devoncarew/firehose/actions/workflows/dart.yaml/badge.svg)](https://github.com/devoncarew/firehose/actions/workflows/dart.yaml)
[![pub package](https://img.shields.io/pub/v/firehose.svg)](https://pub.dev/packages/firehose)
[![package publisher](https://img.shields.io/pub/publisher/firehose.svg)](https://pub.dev/packages/firehose/publisher)

## What's this?

This is a tool to automate publishing pub packages from GitHub actions.

## Status

This is very much still a work in progress! This is not yet something to rely on.

## Conventions

- when run from a PR branch, this tool will validate the changed files, pubspecs,
  and changelogs, and indicate whether the criteria for publishing has been met
- when run from a merge into the default branch, this tool will attempt to
  publish any packages which have had changed files
- the pubspec should contain the `auto_publish: true` property in order for this
  tool to attempt to auto-publish it

Additionally:
- each PR should add a new entry to the changelog
- the changelog version and pubspec version should agree

## Integrating this into a repo

TODO: instructions to follow
