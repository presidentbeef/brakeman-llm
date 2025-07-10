require 'brakeman'
require 'brakeman/warning'
require 'ruby_llm'

# Override Brakeman::Warning to add LLM analysis of warning
module Brakeman
  class Warning
    attr_accessor :analysis

    alias old_to_hash to_hash

    def to_hash(...)
      old_to_hash(...).tap do |h|
        h[:analysis] = self.analysis
      end
    end
  end
end

module Brakeman

  # Simple wrapper for RubyLLM
  class LLM

    # Configure RubyLLM
    def initialize(model:, provider:, **kwargs)
      @llm = RubyLLM.context do |config|
        kwargs.each do |k, v|
          config.send("#{k}=", v)
        end
      end

      RubyLLM.logger.level = Logger::ERROR

      @chat = @llm.chat(model: model, provider: provider)
      @chat.with_instructions("You are a world-class application security expert with deep expertise in Ruby and Ruby on Rails security.")
    end

    # Analyze single Brakeman warning.
    # Results analysis as a string.
    def analyze_warning(warning)
      response = @chat.ask <<~INPUT
        Analyze the following security warning resulting from analyzing a Ruby on Rails application with the static analysis security tool Brakeman.
        Explain the security vulnerability and potential fixes. Jump straight into the explanation, do not have a casual introduction.
        Ignore 'fingerprint' and 'warning_code' fields and do not explain them.

        Security warning in JSON format that describes a potential security vulnerability:
        #{warning.to_json}
      INPUT

      response.content
    end
  end

  class << self
    alias old_run run

    def run(options)
      if options[:llm]
        llm_opts = options.delete(:llm)
        llm = Brakeman::LLM.new(**llm_opts)

        # Suppress report output until after analysis
        output_files = options.delete(:output_files)
        output_formats = options.delete(:output_formats)
        print_report = options.delete(:print_report)

        tracker = old_run(options)

        tracker.warnings.each do |warning|
          warning.analysis = llm.analyze_warning(warning)
        end

        if output_files
          notify "Generating report..."

          write_report_to_files tracker, options[:output_files]
        elsif print_report
          notify "Generating report..."

          write_report_to_formats tracker, options[:output_formats]
        end

        tracker
      else
        raise 'Setup LLM options using `llm: { model: ..., provider: ...,  etc.}` option to Brakeman.run()'
      end
    end
  end
end
