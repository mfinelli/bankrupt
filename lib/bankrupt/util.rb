# frozen_string_literal: true

module Bankrupt
  # Utilities for working with asset manifest files.
  class Util
    # Parse the asset manifest
    #
    # @param path [String] path to the manifest
    # @return [Hash] parsed manifest or empty hash on error
    def self.parse_manifest(path)
      Hash[JSON.parse(File.read(path)).map do |k, v|
        [k.freeze, Hash[v.map { |l, b| [l.to_sym, b.freeze] }].freeze]
      end].freeze
    rescue StandardError
      {}
    end
  end
end
