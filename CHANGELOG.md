# Bankrupt Change Log

This file keeps track of changes between releases for the bankrupt project
which adheres to [semantic versioning](https://semver.org).

## v3.0.0 2021-08-21

* Drop support for ruby 2.4.x.
* Mark uploaded assets as `immutable` in the `Cache-Control` header.

## v2.1.2 2020-01-20

Take options into account to ensure unique asset lookups.

## v2.1.1 2020-01-09

Ensure that the `purge` task works with hashless assets.

## v2.1.0 2020-01-06

Add support for unversioned ("hashless") assets.

* Add new configuration file and `hashless` option (file glob array) to upload
  files to the CDN without their md5 hash appended.
* Add new `raw` helper to just return the full URL of an asset.
* Add upload support for PDF files.

## v2.0.1 2019-07-30

Add support for uploading font files (`eot`, `ttf`, `woff`, and `woff2`) to
the cdn during the `bankrupt:cdn` rake task.

## v2.0.0 2019-06-12

This major release changes the default cache behavior of assets uploaded to s3
to make them expire in one year.

* Set cache-control header on objects uploaded to s3 (1 year).
* Add new rake task to remove old objects (anything not in the current
  manifest) from s3.
* Extend test covertage to rake tasks.
* Drop support for ruby 2.3.x which might be considered breaking, but has
  actually always been the case just unnoticed until the test coverage was
  extended and exposed the problem, so I'm considering it a bugfix.

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
