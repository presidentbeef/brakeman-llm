require 'minitest/autorun'
require 'brakeman-llm'
require 'brakeman/commandline'


class BrakemanLLMTest < Minitest::Test
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
      tracker = Brakeman.run(llm: { llm: bm_llm }, app_path: File.join(__dir__, 'fixtures', 'app'), output_format: :json)
    end

    # Check that the warnings have the analysis attached
    tracker.warnings.each do |w|
      assert_includes w.llm_analysis, analysis

      assert_equal w.llm_analysis, w.to_hash[:llm_analysis]
    end

    chat_mock.verify
    response_mock.verify
  end
end
