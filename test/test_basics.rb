require 'minitest/autorun'
require 'brakeman-llm'
require 'brakeman/commandline'


class BrakemanLLMTest < Minitest::Test
  def rails_app(id = 1)
    File.join(__dir__, 'fixtures', "rails_app_#{id}")
  end

  def test_the_basics
    bm_llm = Brakeman::LLM.new(model: 'test_model', provider: 'test_provider')

    assert_equal 'test_model', bm_llm.model
    assert_equal 'test_provider', bm_llm.provider
    assert bm_llm.llm

    # Defaults
    assert_instance_of String, bm_llm.instructions
    assert_instance_of String, bm_llm.prompt
  end

  def test_missing_options

  end

  def test_end_to_end
    bm_llm = Brakeman::LLM.new(model: 'test_model', provider: 'test_provider')
    instructions = bm_llm.instructions
    analysis = "Extended warning description"
    tracker = nil

    response_mock = Minitest::Mock.new
    response_mock.expect(:content, analysis.dup)
    response_mock.expect(:content, analysis.dup)

    chat_mock = Minitest::Mock.new

    2.times do
      chat_mock.expect(:with_instructions, nil, [instructions])
      chat_mock.expect(:ask, response_mock, [String])
    end

    bm_llm.llm.stub(:chat, chat_mock) do
      tracker = Brakeman.run(llm: { llm: bm_llm }, app_path: rails_app, output_format: :json)
    end

    # Check that the warnings have the analysis attached
    tracker.warnings.each do |w|
      assert_includes w.llm_analysis, analysis

      assert_equal w.llm_analysis, w.to_hash[:llm_analysis]
    end

    chat_mock.verify
    response_mock.verify
  end

  def test_load_config
    options = {
      app_path: rails_app(2)
    }

    Brakeman.ensure_llm_options(options)

    assert options[:llm]
    assert options[:llm][:api_key]
    assert options[:llm][:api_base]
    assert options[:llm][:provider]
    assert options[:llm][:model]
  end

  def test_no_config
    assert_raises do
      Brakeman.run(app_path: rails_app)
    end
  end

  def test_llm_options_from_config
    options = {
      app_path: rails_app(2)
    }

    Brakeman.ensure_llm_options(options)

    llm_opts = options[:llm]
    bm_llm = Brakeman::LLM.new(**llm_opts)

    assert_equal llm_opts[:provider], bm_llm.provider
    assert_equal llm_opts[:model], bm_llm.model

    assert_equal llm_opts[:api_key], bm_llm.llm.config.openai_api_key
    assert_equal llm_opts[:api_base], bm_llm.llm.config.openai_api_base

    assert bm_llm.assume_model_exists
    assert bm_llm.llm.config.openai_use_system_role
  end

  def test_disclaimer
    bm_llm = Brakeman::LLM.new(model: 'test_model', provider: 'test_provider')
    instructions = bm_llm.instructions
    analysis = 'Extended warning description'
    disclaimer = 'LLMs can be wrong'
    tracker = nil

    response_mock = Minitest::Mock.new
    response_mock.expect(:content, analysis.dup)
    response_mock.expect(:content, analysis.dup)

    chat_mock = Minitest::Mock.new

    2.times do
      chat_mock.expect(:with_instructions, nil, [instructions])
      chat_mock.expect(:ask, response_mock, [String])
    end

    bm_llm.llm.stub(:chat, chat_mock) do
      tracker = Brakeman.run(llm: { llm: bm_llm, disclaimer: disclaimer }, app_path: rails_app)
    end

    # Check that the warnings have the disclaimer attached
    tracker.warnings.each do |w|
      assert_includes w.message.to_s, disclaimer 
    end

    chat_mock.verify
    response_mock.verify
  end

  def test_disclaimer_in_json
    bm_llm = Brakeman::LLM.new(model: 'test_model', provider: 'test_provider')
    instructions = bm_llm.instructions
    analysis = 'Extended warning description'
    disclaimer = 'LLMs can be wrong'
    tracker = nil

    response_mock = Minitest::Mock.new
    response_mock.expect(:content, analysis.dup)
    response_mock.expect(:content, analysis.dup)

    chat_mock = Minitest::Mock.new

    2.times do
      chat_mock.expect(:with_instructions, nil, [instructions])
      chat_mock.expect(:ask, response_mock, [String])
    end

    bm_llm.llm.stub(:chat, chat_mock) do
      tracker = Brakeman.run(llm: { llm: bm_llm, disclaimer: disclaimer }, app_path: rails_app, output_format: :json)
    end

    # Check that the warnings have the disclaimer attached
    tracker.warnings.each do |w|
      assert_includes w.llm_analysis, disclaimer
    end

    chat_mock.verify
    response_mock.verify
  end

  def test_error_during_analysis
    bm_llm = Brakeman::LLM.new(model: 'test_model', provider: 'test_provider')
    analysis = 'Extended warning description'
    tracker = nil

    chat_mock = -> (_) { raise RubyLLM::Error }

    bm_llm.llm.stub(:chat, chat_mock) do
      tracker = Brakeman.run(llm: { llm: bm_llm }, app_path: rails_app, output_format: :json)
    end

    tracker.warnings.each do |w|
      assert_nil w.llm_analysis
    end
  end
end
