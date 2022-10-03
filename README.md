[![Dart](https://github.com/devoncarew/firehose/actions/workflows/dart.yaml/badge.svg)](https://github.com/devoncarew/firehose/actions/workflows/dart.yaml)
[![pub package](https://img.shields.io/pub/v/firehose.svg)](https://pub.dev/packages/firehose)
[![package publisher](https://img.shields.io/pub/publisher/firehose.svg)](https://pub.dev/packages/firehose/publisher)

## What's this?

This is a tool to automate publishing of pub packages from GitHub actions.

## Status

This is very much still a work in progress! This is not yet recommended for
production services.

## Conventions

- pubspecs should contain an `auto_publish: true` property in order for this
  tool to attempt to auto-publish
- when run from a PR branch, this tool will validate the changed files, pubspecs,
  and changelogs, and indicate whether the criteria for publishing has been met
- when run from a merge into the default branch, this tool will attempt to
  publish any packages which have had changed files

Additionally:
- each PR should add a new entry to the changelog
- the changelog version and pubspec version should agree

## Skipping changelog validation for a PR

To skip the package validation for a PR, add a `changelog-exempt` label to the
PR. This should only be used for trivial changes that are not in any way user
facing.

## Pre-release versions

Pre-release versions (aka, `'1.2.3-foo'`) are handled specially; this tool
will validate the package changes, but will not auto-publish the package. This
can be used to accumulate several changes and later publish them as a group.
When the version later changes to a stable version (above, `'1.2.3`), the tool
will publish that verion.

## Disabling off auto-publishing

There are several ways to turn off auto-publishing; this includes:

- changing the `auto_publish` value in the pubspec to any value other than
`true`
- adding a `publish-to: none` value to your pubspec

## PR branch actions

For a PR, this tool:

- determines changed files
- determines affected packages
- validates that there's a changelog entry
- validates that the changelog version == the pubspec version

## Default branch actions

For a merge into the default branch, this tool:

- determines changed files
- determines affected packages
- attempts to publish
- tags the commit and push the tag

## Mono-repos

This tool can work with either single package repos or with mono-repos (repos
containing several packages). It will scan for and detect any package which
has the `auto_publish: true` property set in its pubspec.

After a successful publish, for single package repos, the commit will be tagged
with the package version (i.e., `1.2.3`). For mono-repos, in order to differentiate
between other packages in the repo, the commit will be tagged with the package
name and version (i.e., `foo-v1.2.3`).

## Integrating this tool into a repo

- create a repository secret on your repo called `PUB_CREDENTIALS`; this should
  contain the contents of your Pub oauth credentials file
- configure your repo to squash commits when merging PRs; otherwise this action
  will run for each separate commit in a PR when merged
- copy the .github/workflows/publish.yaml file to your repo
- update that file to invoke this tool via pub global activate (i.e.,
  `dart pub global activate firehose`; `dart pub global run firehose`)
