[![Dart](https://github.com/devoncarew/firehose/actions/workflows/dart.yaml/badge.svg)](https://github.com/devoncarew/firehose/actions/workflows/dart.yaml)
[![pub package](https://img.shields.io/pub/v/firehose.svg)](https://pub.dev/packages/firehose)
[![package publisher](https://img.shields.io/pub/publisher/firehose.svg)](https://pub.dev/packages/firehose/publisher)

## What's this?

This is a tool to automate publishing of pub packages from GitHub actions.

## Conventions and setup

When run from a PR branch, this tool will validate the package pubspecs and
and changelogs, and indicate whether the criteria for publishing has been met.
Each PR should add a new entry to the changelog and the changelog version and
pubspec version should agree.

When run in reponse to a git tag event (a tag with a pattern like `v1.2.3` or
`name_v1.2.3` for monorepos), this tool will publish the indicated package.

## Pre-release versions

Pre-release versions (aka, `'1.2.3-dev'`) are handled specially; this tool will
validate the package but will not auto-publish it. This can be used to
accumulate several changes and later publish them as a group.

## Disabling auto-publishing

In order to disable package validation and auto-publishing, `publish_to: none`
key to your pubspec (see also https://dart.dev/tools/pub/pubspec#publish_to).

## PR branch actions

For a PR, this tool:

- determines repo packages
- validates that there is a changelog entry
- validates that the changelog version equals the pubspec version

## Git tag actions

In reponse to a git tag event, this tool:

- validates the tag is well-formed
- determines the indicated package
- attempts to publish that package

## Mono-repos

This tool can work with either single package repos or with mono-repos (repos
containing several packages). It will scan for and detect packages in a mono
repo; to omit packages from validation and auto-publishing, add a
`publish_to: none` key to its pubspec.

For single package repos, the tag pattern should be `v1.2.3`. For mono-repos,
the tage pattern be prefixed with the package name, e.g. `foo-v1.2.3`.

## Integrating this tool into a repo

- copy the .github/workflows/publish.yaml file to your repo
- update that file to invoke this tool via pub global activate (i.e.,
  `dart pub global activate firehose`; `dart pub global run firehose`)
