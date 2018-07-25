require 'slim'
require_relative '../lib/bankrupt'

RSpec.describe Bankrupt do
  let(:klass) do
    Class.new do
      attr_accessor :_assets
      include Bankrupt
      def initialize
        @_assets = {}
      end
    end
  end

  describe '#javascript' do
    context 'with no cdn url' do
      before { stub_const('CDN', '') }

      context 'with the asset in the manifest' do
        before do
          stub_const('ASSETS',
                     'js/present.js' => {
                       filename: 'js/present.js',
                       md5: 'abc',
                       sri: '123'
                     },
                     'js/boom.js' => {
                       filename: 'js/boom.js',
                       md5: 'def',
                       sri: '456'
                     },
                     'js/done.js' => {
                       filename: 'js/done.js',
                       md5: 'ghi',
                       sri: '789'
                     })
        end

        context 'with the asset in the lookup cache' do
          let(:i) { klass.new }

          it 'returns the compiled asset' do
            i._assets['/js/present.js'] = 'i exist!'
            expect(i.javascript('js/present.js')).to eq('i exist!')
          end
        end

        context 'with the asset not in the lookup cache' do
          let(:i) { klass.new }

          it 'adds it to the lookup cache' do
            i.javascript('js/boom.js')
            expect(i._assets['/js/boom.js']).to eq('<script ' \
              'crossorigin="anonymous" integrity="456" src="/js/boom.js">' \
              '</script>')
          end

          it 'returns the expected html' do
            expect(i.javascript('js/done.js')).to eq('<script ' \
              'crossorigin="anonymous" integrity="789" src="/js/done.js">' \
              '</script>')
          end
        end
      end

      context 'with the asset not in the manifest' do
        before { stub_const('ASSETS', {}) }

        context 'with the asset in the lookup cache' do
          let(:i) { klass.new }

          it 'returns the compiled asset' do
            i._assets['/js/exists.js'] = 'i already exist'
            expect(i.javascript('js/exists.js')).to eq('i already exist')
          end
        end

        context 'with the asset not in the lookup cache' do
          let(:i) { klass.new }

          it 'adds it to the lookup cache' do
            i.javascript('js/test.js')
            expect(i._assets['/js/test.js']).to eq('<script ' \
              'src="/js/test.js"></script>')
          end

          it 'returns the expected html' do
            expect(i.javascript('js/html.js')).to eq('<script ' \
              'src="/js/html.js"></script>')
          end
        end
      end
    end

    context 'with a cdn url' do
      before { stub_const('CDN', 'https://example.com') }

      context 'with the asset in the manifest' do
        before do
          stub_const('ASSETS',
                     'js/deja.js' => {
                       filename: 'js/deja.js',
                       md5: 'abc',
                       sri: '123'
                     },
                     'js/add.js' => {
                       filename: 'js/add.js',
                       md5: 'def',
                       sri: '456'
                     },
                     'js/cdn.js' => {
                       filename: 'js/cdn.js',
                       md5: 'ghi',
                       sri: '789'
                     })
        end

        context 'with the asset in the lookup cache' do
          let(:i) { klass.new }

          it 'returns the compiled asset' do
            i._assets['/js/deja.js'] = 'already here'
            expect(i.javascript('js/deja.js')).to eq('already here')
          end
        end

        context 'with the asset not in the lookup cache' do
          let(:i) { klass.new }

          it 'adds it to the lookup cache' do
            i.javascript('js/add.js')
            expect(i._assets['/js/add.js']).to eq('<script ' \
              'crossorigin="anonymous" integrity="456" ' \
              'src="https://example.com/js/add-def.js"></script>')
          end

          it 'returns the expected html' do
            expect(i.javascript('js/cdn.js')).to eq('<script ' \
              'crossorigin="anonymous" integrity="789" ' \
              'src="https://example.com/js/cdn-ghi.js"></script>')
          end
        end
      end

      context 'with the asset not in the manifest' do
        before { stub_const('ASSETS', {}) }

        context 'with the asset in the lookup cache' do
          let(:i) { klass.new }

          it 'returns the compiled asset' do
            i._assets['/js/gia.js'] = 'yes'
            expect(i.javascript('js/gia.js')).to eq('yes')
          end
        end

        context 'with the asset not in the lookup cache' do
          let(:i) { klass.new }

          it 'adds it to the lookup cache' do
            i.javascript('js/piu.js')
            expect(i._assets['/js/piu.js']).to eq('<script ' \
              'src="/js/piu.js"></script>')
          end

          it 'returns the expected html' do
            expect(i.javascript('js/fat.js')).to eq('<script ' \
              'src="/js/fat.js"></script>')
          end
        end
      end
    end
  end

  describe '#stylesheet' do
    context 'with no cdn url' do
      before { stub_const('CDN', '') }

      context 'with the asset in the manifest' do
        before do
          stub_const('ASSETS',
                     'css/present.css' => {
                       filename: 'css/present.css',
                       md5: 'abc',
                       sri: '123'
                     },
                     'css/boom.css' => {
                       filename: 'css/boom.css',
                       md5: 'def',
                       sri: '456'
                     },
                     'css/done.css' => {
                       filename: 'css/done.css',
                       md5: 'ghi',
                       sri: '789'
                     })
        end

        context 'with the asset in the lookup cache' do
          let(:i) { klass.new }

          it 'returns the compiled asset' do
            i._assets['/css/present.css'] = 'i exist!'
            expect(i.stylesheet('css/present.css')).to eq('i exist!')
          end
        end

        context 'with the asset not in the lookup cache' do
          let(:i) { klass.new }

          it 'adds it to the lookup cache' do
            i.stylesheet('css/boom.css')
            expect(i._assets['/css/boom.css']).to eq('<link ' \
              'crossorigin="anonymous" href="/css/boom.css" integrity="456" ' \
              'rel="stylesheet" />')
          end

          it 'returns the expected html' do
            expect(i.stylesheet('css/done.css')).to eq('<link ' \
              'crossorigin="anonymous" href="/css/done.css" integrity="789" ' \
              'rel="stylesheet" />')
          end
        end
      end

      context 'with the asset not in the manifest' do
        before { stub_const('ASSETS', {}) }

        context 'with the asset in the lookup cache' do
          let(:i) { klass.new }

          it 'returns the compiled asset' do
            i._assets['/css/exists.css'] = 'i already exist'
            expect(i.stylesheet('css/exists.css')).to eq('i already exist')
          end
        end

        context 'with the asset not in the lookup cache' do
          let(:i) { klass.new }

          it 'adds it to the lookup cache' do
            i.stylesheet('css/test.css')
            expect(i._assets['/css/test.css']).to eq('<link ' \
              'href="/css/test.css" rel="stylesheet" />')
          end

          it 'returns the expected html' do
            expect(i.stylesheet('css/html.css')).to eq('<link ' \
              'href="/css/html.css" rel="stylesheet" />')
          end
        end
      end
    end

    context 'with a cdn url' do
      before { stub_const('CDN', 'https://example.com') }

      context 'with the asset in the manifest' do
        before do
          stub_const('ASSETS',
                     'css/deja.css' => {
                       filename: 'css/deja.css',
                       md5: 'abc',
                       sri: '123'
                     },
                     'css/add.css' => {
                       filename: 'css/add.css',
                       md5: 'def',
                       sri: '456'
                     },
                     'css/cdn.css' => {
                       filename: 'css/cdn.css',
                       md5: 'ghi',
                       sri: '789'
                     })
        end

        context 'with the asset in the lookup cache' do
          let(:i) { klass.new }

          it 'returns the compiled asset' do
            i._assets['/css/deja.css'] = 'already here'
            expect(i.stylesheet('css/deja.css')).to eq('already here')
          end
        end

        context 'with the asset not in the lookup cache' do
          let(:i) { klass.new }

          it 'adds it to the lookup cache' do
            i.stylesheet('css/add.css')
            expect(i._assets['/css/add.css']).to eq('<link ' \
              'crossorigin="anonymous" ' \
              'href="https://example.com/css/add-def.css" integrity="456" ' \
              'rel="stylesheet" />')
          end

          it 'returns the expected html' do
            expect(i.stylesheet('css/cdn.css')).to eq('<link ' \
              'crossorigin="anonymous" ' \
              'href="https://example.com/css/cdn-ghi.css" integrity="789" ' \
              'rel="stylesheet" />')
          end
        end
      end

      context 'with the asset not in the manifest' do
        before { stub_const('ASSETS', {}) }

        context 'with the asset in the lookup cache' do
          let(:i) { klass.new }

          it 'returns the compiled asset' do
            i._assets['/css/gia.css'] = 'yes'
            expect(i.stylesheet('css/gia.css')).to eq('yes')
          end
        end

        context 'with the asset not in the lookup cache' do
          let(:i) { klass.new }

          it 'adds it to the lookup cache' do
            i.stylesheet('css/piu.css')
            expect(i._assets['/css/piu.css']).to eq('<link ' \
              'href="/css/piu.css" rel="stylesheet" />')
          end

          it 'returns the expected html' do
            expect(i.stylesheet('css/fat.css')).to eq('<link ' \
              'href="/css/fat.css" rel="stylesheet" />')
          end
        end
      end
    end
  end
end
