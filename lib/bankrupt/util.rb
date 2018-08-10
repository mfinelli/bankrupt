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
