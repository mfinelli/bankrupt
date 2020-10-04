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

  describe '#image' do
    context 'with options' do
      let(:options) { { class: 'img', alt: 'img' } }

      context 'with no cdn url' do
        before { stub_const('CDN', '') }

        context 'with the asset in the manifest' do
          before do
            stub_const('ASSETS',
                       'img/life.jpg' => {
                         filename: 'img/life.jpg',
                         md5: 'abc',
                         sri: '123'
                       },
                       'img/wow.jpg' => {
                         filename: 'img/wow.jpg',
                         md5: 'def',
                         sri: '456'
                       },
                       'img/pod.jpg' => {
                         filename: 'img/pod.jpg',
                         md5: 'ghi',
                         sri: '789'
                       })
          end

          context 'with the asset in the lookup cache' do
            let(:i) { klass.new }

            it 'returns the compiled asset' do
              i._assets['/img/life.jpg?classimgaltimg'] = 'i exist!'
              expect(i.image('img/life.jpg', options)).to eq('i exist!')
            end
          end

          context 'with the asset not in the lookup cache' do
            let(:i) { klass.new }

            it 'adds it to the lookup cache' do
              i.image('img/wow.jpg', options)
              expect(i._assets['/img/wow.jpg?classimgaltimg']).to eq('<img ' \
                'alt="img" class="img" crossorigin="anonymous" ' \
                'src="/img/wow.jpg" />')
            end

            it 'returns the expected html' do
              expect(i.image('img/pod.jpg', options)).to eq('<img ' \
                'alt="img" class="img" crossorigin="anonymous" ' \
                'src="/img/pod.jpg" />')
            end
          end
        end

        context 'with the asset not in the manifest' do
          before { stub_const('ASSETS', {}) }

          context 'with the asset in the lookup cache' do
            let(:i) { klass.new }

            it 'returns the compiled asset' do
              i._assets['/img/key.jpg?classimgaltimg'] = 'i already exist'
              expect(i.image('img/key.jpg', options)).to eq('i already exist')
            end
          end

          context 'with the asset not in the lookup cache' do
            let(:i) { klass.new }

            it 'adds it to the lookup cache' do
              i.image('img/another.jpg', options)
              expect(i._assets['/img/another.jpg?classimgaltimg']).to eq(
                '<img alt="img" class="img" src="/img/another.jpg" />'
              )
            end

            it 'returns the expected html' do
              expect(i.image('img/major.jpg', options)).to eq('<img ' \
                'alt="img" class="img" src="/img/major.jpg" />')
            end
          end
        end

        context 'with the same asset and different options' do
          before do
            stub_const('ASSETS',
                       'img/pic.png' => {
                         filename: 'img/pic.png',
                         md5: 'jkl',
                         sri: '012'
                       })
          end

          let(:i) { klass.new }

          it 'creates two lookup entries' do
            i.image('img/pic.png', class: 'one')
            i.image('img/pic.png', class: 'two')

            ['/img/pic.png?classone', '/img/pic.png?classtwo'].each do |t|
              expect(i._assets[t]).not_to be_nil
            end
          end

          it 'returns the correct html for the first asset' do
            expect(i.image('img/pic.png', class: 'one')).to eq('<img ' \
              'class="one" crossorigin="anonymous" src="/img/pic.png" />')
          end

          it 'returns the correct html for the second asset' do
            expect(i.image('img/pic.png', class: 'two')).to eq('<img ' \
              'class="two" crossorigin="anonymous" src="/img/pic.png" />')
          end
        end
      end

      context 'with a cdn url' do
        before { stub_const('CDN', 'https://example.com') }

        context 'with the asset in the manifest' do
          before do
            stub_const('ASSETS',
                       'img/you.jpg' => {
                         filename: 'img/you.jpg',
                         md5: 'abc',
                         sri: '123'
                       },
                       'img/top.jpg' => {
                         filename: 'img/top.jpg',
                         md5: 'def',
                         sri: '456'
                       },
                       'img/bag.jpg' => {
                         filename: 'img/bag.jpg',
                         md5: 'ghi',
                         sri: '789'
                       },
                       'img/hop.jpg' => {
                         filename: 'img/hop.jpg',
                         md5: 'jkl',
                         sri: '123',
                         hashless: true
                       })
          end

          context 'with the asset in the lookup cache' do
            let(:i) { klass.new }

            it 'returns the compiled asset' do
              i._assets['/img/you.jpg?classimgaltimg'] = 'already here'
              expect(i.image('img/you.jpg', options)).to eq('already here')
            end
          end

          context 'with the asset not in the lookup cache' do
            let(:i) { klass.new }

            it 'adds it to the lookup cache' do
              i.image('img/top.jpg', options)
              expect(i._assets['/img/top.jpg?classimgaltimg']).to eq('<img ' \
                'alt="img" class="img" crossorigin="anonymous" ' \
                'src="https://example.com/img/top-def.jpg" />')
            end

            it 'returns the expected html' do
              expect(i.image('img/bag.jpg', options)).to eq('<img ' \
                'alt="img" class="img" crossorigin="anonymous" ' \
                'src="https://example.com/img/bag-ghi.jpg" />')
            end
          end

          context 'with a hashless asset' do
            let(:i) { klass.new }

            it 'returns the expected html' do
              expect(i.image('img/hop.jpg', options)).to eq('<img ' \
                'alt="img" class="img" crossorigin="anonymous" ' \
                'src="https://example.com/img/hop.jpg" />')
            end
          end
        end

        context 'with the asset not in the manifest' do
          before { stub_const('ASSETS', {}) }

          context 'with the asset in the lookup cache' do
            let(:i) { klass.new }

            it 'returns the compiled asset' do
              i._assets['/img/strap.jpg?classimgaltimg'] = 'yes'
              expect(i.image('img/strap.jpg', options)).to eq('yes')
            end
          end

          context 'with the asset not in the lookup cache' do
            let(:i) { klass.new }

            it 'adds it to the lookup cache' do
              i.image('img/card.jpg', options)
              expect(i._assets['/img/card.jpg?classimgaltimg']).to eq('<img ' \
                'alt="img" class="img" src="/img/card.jpg" />')
            end

            it 'returns the expected html' do
              expect(i.image('img/side.jpg', options)).to eq('<img ' \
                'alt="img" class="img" src="/img/side.jpg" />')
            end
          end
        end
      end
    end

    context 'with no options' do
      context 'with no cdn url' do
        before { stub_const('CDN', '') }

        context 'with the asset in the manifest' do
          before do
            stub_const('ASSETS',
                       'img/life.jpg' => {
                         filename: 'img/life.jpg',
                         md5: 'abc',
                         sri: '123'
                       },
                       'img/wow.jpg' => {
                         filename: 'img/wow.jpg',
                         md5: 'def',
                         sri: '456'
                       },
                       'img/pod.jpg' => {
                         filename: 'img/pod.jpg',
                         md5: 'ghi',
                         sri: '789'
                       })
          end

          context 'with the asset in the lookup cache' do
            let(:i) { klass.new }

            it 'returns the compiled asset' do
              i._assets['/img/life.jpg'] = 'i exist!'
              expect(i.image('img/life.jpg')).to eq('i exist!')
            end
          end

          context 'with the asset not in the lookup cache' do
            let(:i) { klass.new }

            it 'adds it to the lookup cache' do
              i.image('img/wow.jpg')
              expect(i._assets['/img/wow.jpg']).to eq('<img ' \
                'crossorigin="anonymous" src="/img/wow.jpg" />')
            end

            it 'returns the expected html' do
              expect(i.image('img/pod.jpg')).to eq('<img ' \
                'crossorigin="anonymous" src="/img/pod.jpg" />')
            end
          end
        end

        context 'with the asset not in the manifest' do
          before { stub_const('ASSETS', {}) }

          context 'with the asset in the lookup cache' do
            let(:i) { klass.new }

            it 'returns the compiled asset' do
              i._assets['/img/key.jpg'] = 'i already exist'
              expect(i.image('img/key.jpg')).to eq('i already exist')
            end
          end

          context 'with the asset not in the lookup cache' do
            let(:i) { klass.new }

            it 'adds it to the lookup cache' do
              i.image('img/another.jpg')
              expect(i._assets['/img/another.jpg']).to eq('<img ' \
                'src="/img/another.jpg" />')
            end

            it 'returns the expected html' do
              expect(i.image('img/major.jpg')).to eq('<img ' \
                'src="/img/major.jpg" />')
            end
          end
        end
      end

      context 'with a cdn url' do
        before { stub_const('CDN', 'https://example.com') }

        context 'with the asset in the manifest' do
          before do
            stub_const('ASSETS',
                       'img/you.jpg' => {
                         filename: 'img/you.jpg',
                         md5: 'abc',
                         sri: '123'
                       },
                       'img/top.jpg' => {
                         filename: 'img/top.jpg',
                         md5: 'def',
                         sri: '456'
                       },
                       'img/bag.jpg' => {
                         filename: 'img/bag.jpg',
                         md5: 'ghi',
                         sri: '789'
                       },
                       'img/hop.jpg' => {
                         filename: 'img/hop.jpg',
                         md5: 'jkl',
                         sri: '123',
                         hashless: true
                       })
          end

          context 'with the asset in the lookup cache' do
            let(:i) { klass.new }

            it 'returns the compiled asset' do
              i._assets['/img/you.jpg'] = 'already here'
              expect(i.image('img/you.jpg')).to eq('already here')
            end
          end

          context 'with the asset not in the lookup cache' do
            let(:i) { klass.new }

            it 'adds it to the lookup cache' do
              i.image('img/top.jpg')
              expect(i._assets['/img/top.jpg']).to eq('<img ' \
                'crossorigin="anonymous" ' \
                'src="https://example.com/img/top-def.jpg" />')
            end

            it 'returns the expected html' do
              expect(i.image('img/bag.jpg')).to eq('<img ' \
                'crossorigin="anonymous" ' \
                'src="https://example.com/img/bag-ghi.jpg" />')
            end
          end

          context 'with a hashless asset' do
            let(:i) { klass.new }

            it 'returns the expected html' do
              expect(i.image('img/hop.jpg')).to eq('<img ' \
                'crossorigin="anonymous" ' \
                'src="https://example.com/img/hop.jpg" />')
            end
          end
        end

        context 'with the asset not in the manifest' do
          before { stub_const('ASSETS', {}) }

          context 'with the asset in the lookup cache' do
            let(:i) { klass.new }

            it 'returns the compiled asset' do
              i._assets['/img/strap.jpg'] = 'yes'
              expect(i.image('img/strap.jpg')).to eq('yes')
            end
          end

          context 'with the asset not in the lookup cache' do
            let(:i) { klass.new }

            it 'adds it to the lookup cache' do
              i.image('img/card.jpg')
              expect(i._assets['/img/card.jpg']).to eq('<img ' \
                'src="/img/card.jpg" />')
            end

            it 'returns the expected html' do
              expect(i.image('img/side.jpg')).to eq('<img ' \
                'src="/img/side.jpg" />')
            end
          end
        end
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
                     },
                     'js/rap.js' => {
                       filename: 'js/rap.js',
                       md5: 'jkl',
                       sri: '123',
                       hashless: true
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

        context 'with a hashless asset' do
          let(:i) { klass.new }

          it 'returns the expected html' do
            expect(i.javascript('js/rap.js')).to eq('<script ' \
            'crossorigin="anonymous" integrity="123" ' \
            'src="https://example.com/js/rap.js"></script>')
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
                     },
                     'css/day.css' => {
                       filename: 'css/day.css',
                       md5: 'jkl',
                       sri: '123',
                       hashless: true
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

        context 'with a hashless asset' do
          let(:i) { klass.new }

          it 'returns the expected html' do
            expect(i.stylesheet('css/day.css')).to eq('<link ' \
              'crossorigin="anonymous" ' \
              'href="https://example.com/css/day.css" integrity="123" ' \
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

  describe '#raw' do
    context 'with no cdn url' do
      before { stub_const('CDN', '') }

      context 'with the asset in the manifest' do
        let(:i) { klass.new }

        before do
          stub_const('ASSETS',
                     'test.png' => {
                       filename: 'test.png',
                       md5: 'abc',
                       sri: '123'
                     })
        end

        it 'returns the correct path' do
          expect(i.raw('test.png')).to eq('/test.png')
        end
      end

      context 'with the asset not in the manifest' do
        let(:i) { klass.new }

        before { stub_const('ASSETS', {}) }

        it 'returns the correct path' do
          expect(i.raw('ok.png')).to eq('/ok.png')
        end
      end
    end

    context 'with a cdn url' do
      before { stub_const('CDN', 'https://example.com') }

      context 'with the asset in the manifest' do
        before do
          stub_const('ASSETS',
                     'cool.png' => {
                       filename: 'cool.png',
                       md5: 'abc',
                       sri: '123'
                     },
                     'hope.png' => {
                       filename: 'hope.png',
                       md5: 'def',
                       sri: '456',
                       hashless: true
                     })
        end

        context 'with a normal asset' do
          let(:i) { klass.new }

          it 'returns the correct path' do
            expect(i.raw('cool.png')).to eq('https://example.com/cool-abc.png')
          end
        end

        context 'with a hashless asset' do
          let(:i) { klass.new }

          it 'returns the correct path' do
            expect(i.raw('hope.png')).to eq('https://example.com/hope.png')
          end
        end
      end

      context 'with the asset not in the manifest' do
        let(:i) { klass.new }

        before { stub_const('ASSETS', {}) }

        it 'returns the correct path' do
          expect(i.raw('zoom.png')).to eq('/zoom.png')
        end
      end
    end
  end
end
