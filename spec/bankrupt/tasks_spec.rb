# frozen_string_literal: true

# Copyright 2019 Mario Finelli
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative '../../lib/bankrupt/tasks'

RSpec.describe 'bankrupt' do
  before do
    stub_const('APP_ROOT',
               File.expand_path(File.join(File.dirname(__FILE__),
                                          '..', 'fixtures')))
    stub_const('LOG', Logger.new(File::NULL))

    # test that we rename files that have the hash in them from webpack
    File.rename(
      File.join(APP_ROOT, 'public', 'app.js'),
      File.join(APP_ROOT, 'public',
                "app-#{Digest::MD5.file(File.join(APP_ROOT,
                                                  'public', 'app.js'))}.js")
    )
  end

  after do
    FileUtils.rm_r(File.join(APP_ROOT, 'tmp'))
  end

  describe 'manifest' do
    before do
      Rake::Task['bankrupt:manifest'].reenable
      Rake::Task['bankrupt:manifest'].invoke
    end

    it 'generates an asset manifest file' do
      expect(File.exist?(File.join(APP_ROOT, 'tmp', 'assets.json'))).to be(
        true
      )
    end

    it 'doesn\'t include non-globbed files in the manifest' do
      expect(File.read(File.join(APP_ROOT, 'tmp', 'assets.json'))).to eq(
        File.read(File.join(APP_ROOT, 'assets.json')).chomp
      )
    end
  end
end
