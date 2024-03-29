# frozen_string_literal: true

# Copyright 2018-2021 Mario Finelli
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

require 'aws-sdk-s3'
require 'base64'
require 'digest/bubblebabble'
require 'fileutils'
require 'json'
require 'mini_mime'
require 'rake'
require 'yaml'

namespace :bankrupt do
  desc 'Upload files specified in the manifest to s3/cloudfront'
  task cdn: [:manifest] do
    s3 = Aws::S3::Client.new(region: 'eu-west-1')

    JSON.parse(File.read(File.join(APP_ROOT, 'tmp', 'assets.json')),
               symbolize_names: true).each do |_key, asset|
      r = s3.put_object(
        bucket: CDN_BUCKET,
        key: if asset[:hashless]
               File.join(CDN_PREFIX, asset[:filename])
             else
               File.join(CDN_PREFIX,
                         [[
                           asset[:filename].split(
                             ex = File.extname(asset[:filename])
                           ).first, asset[:md5]
                         ].join('-'), ex].join)
             end,
        body: File.read(f = File.join(APP_ROOT, 'public', asset[:filename])),
        acl: 'private',
        # content_md5: Base64.strict_encode64(asset[:md5]),
        content_length: File.size(f),
        content_type: MiniMime.lookup_by_filename(f).content_type,
        cache_control: 'public, max-age=31536000, immutable',
        server_side_encryption: 'AES256',
        storage_class: 'STANDARD',
        metadata: {
          bankruptVersion: "v#{VERSION}"
        }
      )

      LOG.info "Uploaded #{asset[:filename]} (#{r.etag})"
    end
  end

  desc 'Purge files that no longer exist in the manifest from s3/cloudfront'
  task purge: [:manifest] do
    s3 = Aws::S3::Client.new(region: 'eu-west-1')

    r = s3.list_objects_v2(bucket: CDN_BUCKET, prefix: CDN_PREFIX)
    cdn = r[:contents].collect(&:key)

    local = JSON.parse(File.read(File.join(APP_ROOT, 'tmp', 'assets.json')),
                       symbolize_names: true).map do |_key, asset|
      if asset[:hashless]
        File.join(CDN_PREFIX, asset[:filename])
      else
        File.join(
          CDN_PREFIX,
          [[asset[:filename].split(ex = File.extname(asset[:filename])).first,
            asset[:md5]].join('-'), ex].join
        )
      end
    end

    if local.empty?
      LOG.error 'Local manifest returned zero assets, not purging anything'
      exit(1)
    end

    keys = (cdn - local).map do |key|
      LOG.info "Going to purge #{key}"

      {
        key: key
      }
    end

    d = s3.delete_objects(bucket: CDN_BUCKET, delete: { objects: keys })
    LOG.info "Purged #{d.deleted.size} objects from s3"
  end

  desc 'Generate an asset manifest file with sums and hashes'
  task :manifest do
    manifest = {}
    file_glob = '*.{css,jpg,js,pdf,png,svg,eot,ttf,woff,woff2}'

    config = begin
      YAML.safe_load(File.read(File.join(APP_ROOT, '.bankrupt.yml')),
                     [], [], true, symbolize_names: true)
    rescue Errno::ENOENT
      {}
    end

    Dir.glob(File.join(APP_ROOT, 'public', file_glob)).sort.each do |file|
      md5 = Digest::MD5.file(file).to_s
      basename = File.basename(file)

      # undo the hash that we have webpack insert (but is important so the
      # final css uses the correct path)
      if basename.match?(/-#{md5}\.#{File.extname(file).delete('.')}$/)
        File.rename(file,
                    (file = File.join(
                      File.dirname(file),
                      (basename = basename.gsub("-#{md5}", ''))
                    )))
      end

      manifest[basename] = {
        filename: basename,
        md5: md5,
        babble: Digest::MD5.file(file).bubblebabble,
        sri: "sha384-#{Digest::SHA384.file(file).base64digest}"
      }

      Array(config[:hashless]).each do |match|
        # skip unless the file is in a "hashless" glob
        next unless Dir.glob(File.join(APP_ROOT, 'public', match)).map do |f|
                      File.basename(f)
                    end.include?(basename)

        manifest[basename][:hashless] = true
        break
      end
    end

    LOG.info "Generated asset manifest with #{manifest.keys.size} entries"

    FileUtils.mkdir_p(File.join(APP_ROOT, 'tmp'))
    File.write(File.join(APP_ROOT, 'tmp', 'assets.json'),
               JSON.generate(manifest))
  end
end
