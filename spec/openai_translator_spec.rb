# frozen_string_literal: true

require 'spec_helper'
require 'i18n/tasks/translators/openai_translator'

RSpec.describe 'OpenAI Translation' do
  let(:messages) { [{ role: 'user', content: '["Hello"]' }] }

  # `initialize` requires the optional `ruby-openai` gem, which is not a development dependency.
  def translator_with(config)
    i18n_tasks = instance_double(I18n::Tasks::BaseTask, translation_config: config.with_indifferent_access)
    I18n::Tasks::Translators::OpenAiTranslator.allocate.tap do |translator|
      translator.instance_variable_set(:@i18n_tasks, i18n_tasks)
    end
  end

  def chat_parameters(config)
    translator_with(config).send(:chat_parameters, messages)
  end

  describe '#chat_parameters' do
    it 'sends a zero temperature and no reasoning effort by default' do
      expect(chat_parameters({})).to eq(model: 'gpt-3.5-turbo', messages: messages, stream: false, temperature: 0.0)
    end

    it 'sends the configured model and temperature' do
      parameters = chat_parameters(openai_model: 'gpt-4o-mini', openai_temperature: 0.3)

      expect(parameters).to include(model: 'gpt-4o-mini', temperature: 0.3)
      expect(parameters).not_to have_key(:reasoning_effort)
    end

    it 'sends reasoning effort without a temperature' do
      parameters = chat_parameters(openai_model: 'gpt-6-luna', openai_reasoning_effort: 'low')

      expect(parameters).to include(model: 'gpt-6-luna', reasoning_effort: 'low')
      expect(parameters).not_to have_key(:temperature)
    end

    it 'keeps the temperature when reasoning effort is none' do
      parameters = chat_parameters(openai_reasoning_effort: 'none', openai_temperature: 1.0)

      expect(parameters).to include(reasoning_effort: 'none', temperature: 1.0)
    end

    it 'rejects a temperature combined with an active reasoning effort' do
      expect { chat_parameters(openai_reasoning_effort: 'medium', openai_temperature: 0.2) }
        .to raise_error(I18n::Tasks::CommandError, /openai_temperature is not supported/)
    end
  end
end
