# frozen_string_literal: true

# Copyright 2018 Mario Finelli
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

  private

  # Return a precomputed asset path if it exists
  #
  # @param path [String] asset on which to perform the lookup
  # @return [String] the rendered slim template with the asset in place
  def lookup(path)
    @_assets.fetch(path)
  rescue KeyError
    nil
  end

  # Inserts the md5 hash of the asset into the filename.
  #
  # @param file [String] basename of the asset
  # @param digest [String] md5 hash of the asset
  # @return [String] filename with digest e.g, style-123.css
  def append_md5(file, digest)
    [[file.split(ex = File.extname(file)).first, digest].join('-'), ex].join
  end

  # Generates the full path to the asset including CDN domain, if set.
  #
  # @param path [String] local path to the asset
  # @return [String] new, full path to the asset
  def create_fullpath(path, md5)
    return "/#{path}" if CDN.empty?
    [CDN, append_md5(path, md5)].join('/')
  end

  # Generate the asset HTML. If the asset exists in the lookup hash then
  # return it, otherwise compute the html and save it to the lookup hash.
  #
  # @param path [String] relative path to the asset
  # @param cdn [String] a slim template for generating a cdn asset
  # @param local [String] a slim template for generating a local asset
  # @return [String] the asset html
  def asset_html(path, cdn, local)
    if (asset = lookup("/#{path}"))
      return asset
    end

    begin
      details = ASSETS.fetch(path)

      fullpath = create_fullpath(path, details[:md5])

      @_assets["/#{path}"] = Slim::Template.new { cdn }.render(
        ASSET.new(fullpath, details[:sri])
      )
    rescue KeyError
      @_assets["/#{path}"] = Slim::Template.new { local }.render(
        ASSET.new("/#{path}", nil)
      )
    end
  end
end
