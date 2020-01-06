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

require_relative '../../lib/bankrupt/util'

RSpec.describe Bankrupt::Util do
  describe '.parse_manifest' do
    let(:manifest) { 'spec/fixtures/assets.json' }

    let(:parsed) do
      {
        'app.css' => {
          filename: 'app.css',
          md5: 'a4197ed8dcb93d681801318bd25a41ed',
          babble: 'xonac-nozat-melar-nyzok-mukab-cosim-rigyh-pibuv-texyx',
          sri: 'sha384-3RDtjniIi2E/mmvcXsOOfu/zxDaJoztI9CiXJ4wWylYEw5ReQ+1' \
            'HKelRqeQozAmx'
        },
        'app.js' => {
          filename: 'app.js',
          md5: '9b33890bb13bb1d8f975e9ab3902c05f',
          babble: 'xokof-fodyb-rysof-reset-mevel-hypip-ravib-dibyh-zaxyx',
          sri: 'sha384-b6Ge3qiUuSOTxlLyaCcrcVvMFp9rKcrpxcRlpfVGV6ILhqC7OEpJ' \
            'ezUEfTE6KZ/T'
        },
        'hashless.js' => {
          filename: 'hashless.js',
          md5: '13fa42d157be30d32d1a805ff8af1735',
          babble: 'xegoz-pybat-cihar-vasyt-feroc-pabeh-zavyp-zahef-huxex',
          sri: 'sha384-yuXgTEKrfw3tBVlRAQnTwfx7w+NcSYkIBMDhm86HfozvIPf9VO5v' \
            'FKDyiaqCtILC',
          hashless: true
        }
      }
    end

    it 'returns a hash' do
      expect(described_class.parse_manifest(manifest)).to be_a(Hash)
    end

    it 'returns the correct values' do
      expect(described_class.parse_manifest(manifest)).to eq(parsed)
    end

    it 'deep freezes the hash - keys' do
      described_class.parse_manifest(manifest).each do |k, _|
        expect(k.frozen?).to eq(true)
      end
    end

    it 'deep freezes the hash - values' do
      described_class.parse_manifest(manifest).each do |_, v|
        v.each { |_, s| expect(s.frozen?).to eq(true) }
      end
    end

    it 'returns an empty hash on exception' do
      expect(described_class.parse_manifest('missing.json')).to eq({})
    end
  end
end
