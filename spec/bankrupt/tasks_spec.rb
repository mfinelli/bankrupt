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

    stub_const('CDN_BUCKET', 'bankrupt-test')
    stub_const('CDN_PREFIX', 'test')
    stub_const('VERSION', '1.0.0')

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

  describe 'cdn' do
    before do
      Rake::Task['bankrupt:manifest'].reenable
      Rake::Task['bankrupt:manifest'].invoke
      Rake::Task['bankrupt:cdn'].reenable
    end

    let(:s3_double) { Aws::S3::Client.new(stub_responses: true) }
    let(:s3_response) do
      class MockResponse
        def etag
          'ok'
        end
      end

      MockResponse.new
    end

    it 'uploads files to s3' do
      allow(Aws::S3::Client).to receive(:new).and_return(s3_double)

      expect(s3_double).to receive(:put_object).with(
        bucket: 'bankrupt-test',
        key: 'test/app-a4197ed8dcb93d681801318bd25a41ed.css',
        body: "body {\n  color: red;\n}\n",
        acl: 'private',
        content_length: 23,
        content_type: 'text/css',
        cache_control: 'public, max-age=31536000',
        server_side_encryption: 'AES256',
        storage_class: 'STANDARD',
        metadata: {
          bankruptVersion: 'v1.0.0'
        }
      ).and_return(s3_response)

      expect(s3_double).to receive(:put_object).with(
        bucket: 'bankrupt-test',
        key: 'test/app-9b33890bb13bb1d8f975e9ab3902c05f.js',
        body: "alert('yolo');\n",
        acl: 'private',
        content_length: 15,
        content_type: 'application/ecmascript',
        cache_control: 'public, max-age=31536000',
        server_side_encryption: 'AES256',
        storage_class: 'STANDARD',
        metadata: {
          bankruptVersion: 'v1.0.0'
        }
      ).and_return(s3_response)

      Rake::Task['bankrupt:cdn'].invoke
    end
  end

  describe 'purge' do
    before do
      Rake::Task['bankrupt:manifest'].reenable
      Rake::Task['bankrupt:manifest'].invoke
      Rake::Task['bankrupt:purge'].reenable
    end

    let(:s3_double) { Aws::S3::Client.new(stub_responses: true) }
    let(:s3_response) do
      class MockResponse
        def deleted
          [1]
        end
      end

      MockResponse.new
    end

    it 'exits when there aren\'t any files in the manifest' do
      allow(Aws::S3::Client).to receive(:new).and_return(s3_double)
      allow(s3_double).to receive(:list_objects_v2).and_return(contents: [])
      allow(JSON).to receive(:parse).and_return({})

      expect { Rake::Task['bankrupt:purge'].invoke }.to(
        raise_exception(SystemExit) do |ex|
          expect(ex.status).to eq(1)
        end
      )
    end

    it 'deletes the objects not in the manifest' do
      allow(Aws::S3::Client).to receive(:new).and_return(s3_double)

      s3_double.stub_responses(:list_objects_v2, contents:
        [
          { key: 'test/app-123.css' },
          { key: 'test/app-9b33890bb13bb1d8f975e9ab3902c05f.js' },
          { key: 'test/app-a4197ed8dcb93d681801318bd25a41ed.css' }
        ])

      expect(s3_double).to receive(:delete_objects).with(
        bucket: 'bankrupt-test',
        delete: { objects: [{ key: 'test/app-123.css' }] }
      ).and_return(s3_response)

      Rake::Task['bankrupt:purge'].invoke
    end
  end
end
