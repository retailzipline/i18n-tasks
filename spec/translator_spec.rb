# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Translation' do
  module I18n::Tasks::BaseTask::TranslationTestExtension
    def translate_forest(forest, from:, backend:)
      case backend
      when :test
        I18n::Tasks::Translators::TestTranslator.new(self).translate_forest(forest, from)
      else
        super
      end
    end
  end
  I18n::Tasks::BaseTask.prepend I18n::Tasks::BaseTask::TranslationTestExtension

  module I18n::Tasks::Translators
    class TestTranslator < BaseTranslator
      private

      def translate_values(list, from:, to:, **options)
        list.map { |v| "translated:#{v}" }
      end

      def options_for_html
        {}
      end

      def options_for_plain
        {}
      end

      def options_for_translate_values(options)
        options
      end
    end
  end

  let(:task) { I18n::Tasks::BaseTask.new }
  let(:base_keys) do
    {
      regular_key: 'a',

      plural_key: {
        one: 'one',
        other: '%{count}'
      },

      not_really_plural: {
        one: 'a',
        green: 'b'
      },

      nested: {
        plural_key: {
          zero: 'none',
          one: 'one',
          other: '%{count}'
        }
      },

      ignored_pattern: {
        plural_key: {
          other: '%{count}'
        }
      }
    }
  end

  around do |ex|
    TestCodebase.setup(
      'config/i18n-tasks.yml' => {
        base_locale: 'en',
        locales: %w[en ru],
        translation_backend: :test,
        ignore_missing: ['ignored_pattern.*']
      }.to_yaml,
      'config/locales/en.yml' => { en: base_keys }.to_yaml,
      'config/locales/ru.yml' => { ru: base_keys.except(:plural_key).deep_merge({ nested: { plural_key: { many: 'existing' } } }) }.to_yaml
    )
    TestCodebase.in_test_app_dir { ex.call }
    TestCodebase.teardown
  end

  describe '#missing' do
    let(:ru_hash) do
      {
        'ru' => {
          'plural_key' => {
            'one' => 'translated:one',
            'few' => 'translated:%{count}',
            'many' => 'translated:%{count}',
            'other' => 'translated:%{count}'
          },
          'nested' => {
            'plural_key' => {
              'few' => 'translated:%{count}'
            }
          }
        }
      }
    end

    it 'translates missing plural keys' do
      missing = task.missing_plural_forest(['ru'], 'en')
      result = task.translate_forest(missing, from: 'en', backend: :test)

      expect(result.to_hash).to eq(ru_hash)
    end
  end

  describe 'multi-line' do

  end
end
