# frozen_string_literal: true

# Copyright 2018-2020 Mario Finelli
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

require 'slim'

# Read assets from a local cache, using files on disk for development and
# from a CDN url if the CDN constant is set.
module Bankrupt
  ASSET = Struct.new(:path, :sri).freeze

  IMAGE_CDN = <<~SLIM
    img crossorigin='anonymous' src=path
  SLIM

  IMAGE_LOCAL = <<~SLIM
    img src=path
  SLIM

  JAVASCRIPT_CDN = <<~SLIM
    script crossorigin='anonymous' integrity=sri src=path
  SLIM

  JAVASCRIPT_LOCAL = <<~SLIM
    script src=path
  SLIM

  STYLESHEET_CDN = <<~SLIM
    link crossorigin='anonymous' href=path integrity=sri rel='stylesheet'
  SLIM

  STYLESHEET_LOCAL = <<~SLIM
    link href=path rel='stylesheet'
  SLIM

  # Return an image html tag for the asset.
  #
  # @todo we compute the options on every call, we should do the
  #        lookup first and short circuit
  #
  # @param path [String] relative (from public) path to the img
  # @param options [Hash] additional attributes to add to the img tag
  # @return [String] image html element
  def image(path, options = {})
    o = Hash(options).map { |k, v| "#{k}='#{v}'" }.join(' ')

    asset_html(path, [IMAGE_CDN.chomp, o].join(' '),
               [IMAGE_LOCAL.chomp, o].join(' '), options)
  end

  # Return a javascript html tag for the asset.
  #
  # @param path [String] relative (from public) path to the js
  # @return [String] script html element
  def javascript(path)
    asset_html(path, JAVASCRIPT_CDN, JAVASCRIPT_LOCAL)
  end

  # Return a stylesheet html tag for the asset.
  #
  # @param path [String] relative (from public) path to the css
  # @return [String] stylesheet html element
  def stylesheet(path)
    asset_html(path, STYLESHEET_CDN, STYLESHEET_LOCAL)
  end

  # Get the full path to the asset for use in e.g. a tags.
  #
  # @param path [String] relative (from public) path to the asset
  # @return [String] full path to the asset
  def raw(path)
    details = ASSETS.fetch(path)
    create_fullpath(path, details[:md5], hashless: details[:hashless])
  rescue KeyError
    "/#{path}"
  end

  private

  # Return a precomputed asset path if it exists
  #
  # @param path [String] asset on which to perform the lookup
  # @params options [String] the options string to use in the lookup
  # @return [String] the rendered slim template with the asset in place
  def lookup(path, options = nil)
    if actual_options?(options)
      @_assets.fetch([path, options].join('?'))
    else
      @_assets.fetch(path)
    end
  rescue KeyError
    nil
  end

  # Inserts the md5 hash of the asset into the filename.
  #
  # @param file [String] basename of the asset
  # @param digest [String] md5 hash of the asset
  # @param hashless [Boolean] if the file doesn't have the hash appended
  # @return [String] filename with digest e.g, style-123.css (style.css if
  #                  hashless)
  def append_md5(file, digest, hashless: false)
    return file if hashless

    [[file.split(ex = File.extname(file)).first, digest].join('-'), ex].join
  end

  # Generates the full path to the asset including CDN domain, if set.
  #
  # @param path [String] local path to the asset
  # @param md5 [String] md5 hash of the asset
  # @param hashless [Boolean] if the files doesn't have the hash appended
  # @return [String] new, full path to the asset
  def create_fullpath(path, md5, hashless: false)
    return "/#{path}" if CDN.empty?

    [CDN, append_md5(path, md5, hashless: hashless)].join('/')
  end

  # Generate the asset HTML. If the asset exists in the lookup hash then
  # return it, otherwise compute the html and save it to the lookup hash.
  #
  # @param path [String] relative path to the asset
  # @param cdn [String] a slim template for generating a cdn asset
  # @param local [String] a slim template for generating a local asset
  # @param options [String] options as a string to make unique lookups
  # @return [String] the asset html
  def asset_html(path, cdn, local, options = nil)
    opts = options_string(options)

    if (asset = lookup("/#{path}", opts))
      return asset
    end

    lookup_path = "/#{actual_options?(opts) ? [path, opts].join('?') : path}"

    begin
      details = ASSETS.fetch(path)

      fullpath = create_fullpath(path, details[:md5], hashless: details[:hashless])

      @_assets[lookup_path] = Slim::Template.new { cdn }.render(
        ASSET.new(fullpath, details[:sri])
      )
    rescue KeyError
      @_assets[lookup_path] = Slim::Template.new { local }.render(
        ASSET.new("/#{path}", nil)
      )
    end
  end

  # Turn the options hash into a concatenated string for use in the lookup.
  #
  # @param options [Hash] the options has to convert
  # @return [String] concatenated options suitable for use in lookups
  def options_string(options)
    return nil if Hash(options).size.zero?

    options.map do |k, v|
      [k.to_s, v.to_s].join
    end.join.gsub(/[^A-Za-z0-9\-_]/, '')
  end

  # Determine if we actually have options regardless if input is a string,
  # hash, or nil.
  #
  # @param options [String, Hash] options to check
  # @return [Boolean] true if there are options, false otherwise
  def actual_options?(options)
    return false if options.nil?

    if (options.is_a?(String) || options.is_a?(Hash)) && !options.size.zero?
      true
    else
      false
    end
  end
end
