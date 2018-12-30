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

Before loading your app set a few constants:

```ruby
CDN = CONFIG[:cdn_url].to_s.freeze

require 'bankrupt/util'
ASSETS = Bankrupt::Util.parse_manifest(
  File.join(APP_ROOT, 'tmp', 'assets.json')
).freeze
```

Then include bankrupt as a helper in your app:

```ruby
require 'bankrupt'

class App < Sinatra::Base
  set :public_folder, File.join(APP_ROOT, 'public')

  helpers Bankrupt

  # TODO: there is a better way to do this
  def initialize
    @_assets = {}
    super
  end
end
```

Now, in your views you can use the helper methods:

```slim
== stylesheet('app.css')
```

In development mode it will load app.css from your local public directory but
in production it will load the CDN URL and include integrity hashes and
anonymous crossorigin attributes.

There's also a helper for `script` tags:

```slim
== javascript('app.js')
```

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

### Rspec

If you're testing your app with rspec or similar you need to stub the `CDN` and
`ASSETS` constants.

```ruby
require 'rack/test'

RSpec.describe App do
  include Rack::Test::Methods

  before do
    stub_const('CDN', '')
    stub_const('ASSETS', {})
  end

  let(:app) { described_class }

  describe 'GET /' do
    before { get '/' }

    it 'returns a 200' do
      expect(last_response).to be_ok
    end
  end
end
```

## License

```
Copyright 2018 Mario Finelli

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
