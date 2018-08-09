# Bankrupt

[![RubyGems](https://img.shields.io/gem/v/bankrupt.svg)](https://rubygems.org/gems/bankrupt)
[![Build Status](https://travis-ci.org/mfinelli/bankrupt.svg?branch=master)](https://travis-ci.org/mfinelli/bankrupt)
[![Coverage Status](https://coveralls.io/repos/github/mfinelli/bankrupt/badge.svg?branch=master)](https://coveralls.io/github/mfinelli/bankrupt?branch=master)
[![Maintainability](https://api.codeclimate.com/v1/badges/f13a4521623d19c8eb4a/maintainability)](https://codeclimate.com/github/mfinelli/bankrupt/maintainability)
[![Inline docs](http://inch-ci.org/github/mfinelli/bankrupt.svg?branch=master)](http://inch-ci.org/github/mfinelli/bankrupt)

A [sinatra](http://sinatrarb.com) helper to path assets during development and
production.

## Usage

### Sinatra

### Rake

You can use the bundled rake task to generate the manifest file in the correct
format using any assets found in the `public` folder. You can also upload the
assets to an s3 bucket for use with cloudfront as a CDN.

Make sure to add the extra dependencies to your gemfile:

```ruby
gem 'aws-sdk-s3'
gem 'mini_mime'
```

In your rakefile you'll need to define several constants and then include
the tasks:

```ruby
require 'bankrupt/tasks'
require 'logger'

APP_ROOT = __dir__.freeze unless defined?(APP_ROOT)
CDN_BUCKET = 'your-s3-bucket'.freeze unless defined?(CDN_BUCKET)
CDN_PREFIX = 'project'.freeze unless defined?(CDN_PREFIX)

unless defined?(VERSION)
  VERSION = JSON.parse(File.read(File.join(APP_ROOT, 'package.json')),
                       symbolize_names: true).fetch(:version).freeze
end

LOG = Logger.new(STDOUT) unless defined?(LOG)
```

Finally set your default task:

```ruby
task default: if ENV['CLOUDBUILD'].to_s.casecmp?('true')
                %i[bankrupt:cdn]
              else
                %i[bankrupt:manifest]
              end
```
