# Bankrupt Change Log

This file keeps track of changes between releases for the bankrupt project
which adheres to [semantic versioning](https://semver.org).

## unreleased

* Set cache-control header on objects uploaded to s3 (1 year).
* Add new rake task to remove old objects (anything not in the current
  manifest) from s3.

## v1.1.0 2019-06-05

Add support for `img` tags along with the ability to add other attributes.

## v1.0.1 2018-12-30

Add support for slim v4.

## v1.0.0 2018-08-10

First stable release. Combines all old, internal code (rake tasks, helper
module) with new updates (modification for public release, utility methods).

* Add rake task for generating manifest files.
* Add rake task for uploading assets to AWS s3 bucket.
* Add utility method for parsing manifest files.

## v0.1.0 2018-07-25

Initial release.
