[![Dart](https://github.com/devoncarew/firehose/actions/workflows/dart.yaml/badge.svg)](https://github.com/devoncarew/firehose/actions/workflows/dart.yaml)
[![pub package](https://img.shields.io/pub/v/firehose.svg)](https://pub.dev/packages/firehose)
[![package publisher](https://img.shields.io/pub/publisher/firehose.svg)](https://pub.dev/packages/firehose/publisher)

## What's this?

This is a tool to automate publishing of pub packages from GitHub actions.

## Conventions and setup

When run from a PR branch, this tool will validate the changed files, pubspecs,
and changelogs, and indicate whether the criteria for publishing has been met.

When run in reponse to a git tag event (a tag with a pattern like `v1.2.3` or
`name_v1.2.3` for monorepos), this tool will publish the indicated package.

Pubspecs should contain an `auto_publish: true` property in order for this tool
to attempt to auto-publish. Additionally, each PR should add a new entry to the
changelog and the changelog version and pubspec version should agree.

## Skipping changelog validation for a PR

To skip the package validation for a PR, add a `changelog-exempt` label to the
PR. This should only be used for trivial changes that are not user facing.

## Pre-release versions

Pre-release versions (aka, `'1.2.3-dev'`) are handled specially; this tool
will validate the package changes, but will not auto-publish the package. This
can be used to accumulate several changes and later publish them as a group.

## Disabling auto-publishing

There are several ways to turn off auto-publishing; this includes:

- changing the `auto_publish` value in the pubspec to any value other than
`true`
- adding a `publish_to: none` value to your pubspec

## PR branch actions

For a PR, this tool:

- determines changed files
- determines affected packages
- validates that there is a changelog entry
- validates that the changelog version equals the pubspec version

## Git tag actions

In reponse to a git tag event, this tool:

- validate the tag is well-formed
- determines the indicated package
- attempts to publish that package

## Mono-repos

This tool can work with either single package repos or with mono-repos (repos
containing several packages). It will scan for and detect any package which
has the `auto_publish: true` property set in its pubspec.

For single package repos, the tag pattern should be `v1.2.3`. For mono-repos,
the tage pattern be prefixed with the package name, e.g. `foo-v1.2.3`.

## Integrating this tool into a repo

- copy the .github/workflows/publish.yaml file to your repo
- update that file to invoke this tool via pub global activate (i.e.,
  `dart pub global activate firehose`; `dart pub global run firehose`)
- update your package pubspecs to include `auto_publish: true`
