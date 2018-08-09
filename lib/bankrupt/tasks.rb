# frozen_string_literal: true

require 'aws-sdk-s3'
require 'base64'
require 'digest/bubblebabble'
require 'fileutils'
require 'json'
require 'mini_mime'
require 'rake'

namespace :bankrupt do
  desc 'Upload files specified in the manifest to s3/cloudfront'
  task cdn: [:manifest] do
    s3 = Aws::S3::Client.new(region: 'eu-west-1')

    JSON.parse(File.read(File.join(APP_ROOT, 'tmp', 'assets.json')),
               symbolize_names: true).each do |_key, asset|
      r = s3.put_object(
        bucket: CDN_BUCKET,
        key: File.join(CDN_PREFIX,
                       [[
                         asset[:filename].split(
                           ex = File.extname(asset[:filename])
                         ).first, asset[:md5]
                       ].join('-'), ex].join),
        body: File.read(f = File.join(APP_ROOT, 'public', asset[:filename])),
        acl: 'private',
        # content_md5: Base64.strict_encode64(asset[:md5]),
        content_length: File.size(f),
        content_type: MiniMime.lookup_by_filename(f).content_type,
        server_side_encryption: 'AES256',
        storage_class: 'STANDARD',
        metadata: {
          bankruptVersion: "v#{VERSION}"
        }
      )

      LOG.info "Uploaded #{asset[:filename]} (#{r.etag})"
    end
  end

  desc 'Generate an asset manifest file with sums and hashes'
  task :manifest do
    manifest = {}
    file_glob = '*.{css,jpg,js,png,svg}'

    Dir.glob(File.join(APP_ROOT, 'public', file_glob)) do |file|
      md5 = Digest::MD5.file(file).to_s
      basename = File.basename(file)

      # undo the hash that we have webpack insert (but is important so the
      # final css uses the correct path)
      if basename.match?(/\-#{md5}\.#{File.extname(file).delete('.')}$/)
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
        sri: 'sha384-' + Digest::SHA384.file(file).base64digest.to_s
      }
    end

    LOG.info "Generated asset manifest with #{manifest.keys.size} entries."

    FileUtils.mkdir_p(File.join(APP_ROOT, 'tmp'))
    File.write(File.join(APP_ROOT, 'tmp', 'assets.json'),
               JSON.generate(manifest))
  end
end
