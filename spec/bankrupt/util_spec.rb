# frozen_string_literal: true

require_relative '../../lib/bankrupt/util'

RSpec.describe Bankrupt::Util do
  describe '.parse_manifest' do
    let(:manifest) { 'spec/fixtures/assets.json' }

    let(:parsed) do
      {
        'app.css' =>
         {
           filename: 'app.css',
           md5: 'de103ea8f44fbb825e5473330a044ce7',
           babble: 'xulic-bozap-mitig-zivom-daleh-gasyf-fydib-gufuv-luxyx',
           sri: 'sha384-8ZoS950YSriGplctgmHuPrmATUDeXhr7uNAOLjBr0Bvf8rK6kXNbTjAIg+dsndV4'
         },
        'app.js' =>
        {
          filename: 'app.js',
          md5: 'd35bd25b09a2bfb2287cc7fd34355ef0',
          babble: 'xugoh-rugah-radap-dyzyr-dapel-sycoz-tataf-hulyz-bexyx',
          sri: 'sha384-elD8v2HdWnnSjP8gWmCo6tkrQ06ch/H5UA1RSFZRQFwPuaSqvsO4EXRYmfh2mUMl'
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
