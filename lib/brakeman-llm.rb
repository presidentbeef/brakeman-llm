require 'brakeman'
require 'brakeman/warning'
require 'brakeman/options'
require 'ruby_llm'

# Override Brakeman::Warning to add LLM analysis of warning
module Brakeman
  class Warning
    attr_accessor :llm_analysis

    alias old_to_hash to_hash

    def to_hash(...)
      old_to_hash(...).tap do |h|
        h[:llm_analysis] = self.llm_analysis
      end
    end
  end
end

module Brakeman

  # Simple wrapper for RubyLLM
  class LLM
    attr_accessor :instructions, :model, :prompt, :provider
    attr_reader :llm

    # Configure RubyLLM
    def initialize(model:, provider:, instructions: nil, prompt: nil, **kwargs)
      @llm = RubyLLM.context do |config|
        kwargs.each do |k, v|
          case k
          when :api_key, :api_base
            config.send("#{provider}_#{k}=", v)
          else
            config.send("#{k}=", v)
          end
        end

        config.log_level = :error unless kwargs.key? :log_level
      end

      RubyLLM.logger.level = Logger::ERROR if @llm.config.log_level == :error

      @instructions = instructions || 'You are a world-class application security expert with deep expertise in Ruby and Ruby on Rails security.'

      @prompt = prompt || <<~PROMPT
        Analyze the following security warning resulting from analyzing a Ruby on Rails application with the static analysis security tool Brakeman.
        Explain the security vulnerability and potential fixes. Jump straight into the explanation, do not have a casual introduction.
        Do not ask follow-up questions, as this is not an interactive prompt.
        Keep the explanation to less than 400 words.
        Ignore 'fingerprint' and 'warning_code' fields and do not explain them.
      PROMPT

      @model = model
      @provider = provider
    end

    # Analyze single Brakeman warning.
    # Results analysis as a string.
    def analyze_warning(warning)
      chat = @llm.chat(model: @model, provider: @provider)
      chat.with_instructions(@instructions)

      llm_input = <<~INPUT
        #{@prompt}
        #{help_doc(warning)}

        The following is a Brakeman security warning in JSON format that describes a potential security vulnerability:
        #{warning.to_json}
      INPUT

      response = chat.ask llm_input

      response.content
    end

    def help_doc(warning)
      if warning.link.match %r{https://brakemanscanner.org/(.+)/}
        doc = File.join(__dir__, '..', $1, "index.markdown")

        if File.exist? doc
          content = File.read doc
          "Here is background information about this type of vulnerability: #{content}"
        else
          puts "No file: #{doc}"
        end
      end
    end
  end

  module Options
    class << self
      alias old_create create_option_parser

      def create_option_parser(options)
        parser = old_create(options)

        parser.separator ""
        parser.separator "LLM Options:"

        # Add LLM options
        parser.on '--llm-model MODEL' do |model|
          options[:llm] ||= {}
          options[:llm][:model] = model
        end

        parser.on '--llm-provider PROVIDER', 'LLM provider (openai, ollama, gemini, etc.)' do |provider|
          options[:llm] ||= {}
          options[:llm][:provider] = provider
        end

        parser.on '--llm-api_key API_KEY', 'LLM provider API key' do |api_key|
          options[:llm] ||= {}
          options[:llm][:api_key] = api_key
        end

        parser.on '--llm-api_base BASE_URL', 'LLM provider base URL' do |url|
          options[:llm] ||= {}
          options[:llm][:api_base] = url
        end

        parser.on '--[no-]llm-disclaimer [DISCLAIMER]', 'Disclaimer to add to each generated message' do |disclaimer|
          options[:llm] ||= {}

          if disclaimer
            options[:llm][:disclaimer] = disclaimer
          else
            options[:llm][:disclaimer] = :none
          end
        end

        parser.separator ""

        parser
      end
    end
  end

  class << self
    alias old_run run

    def run(options)
      if options[:llm]

        disclaimer = options[:llm].delete(:disclaimer) || '(The above message is auto-generated and may contain errors.)'
        if disclaimer == :none
          disclaimer = false
        end

        llm_opts = options.delete(:llm) || {}

        # Suppress report output until after analysis
        output_formats = get_output_formats(options)
        output_files = options.delete(:output_files)
        options.delete(:output_format)
        print_report = options.delete(:print_report)

        # Actually run scan
        tracker = old_run(options)

        # Set up LLM
        llm_opts[:log_level] = :debug if @debug
        llm = llm_opts.delete(:llm) || Brakeman::LLM.new(**llm_opts)

        set_analysis = output_formats.include? :to_json

        notify 'Asking LLM for extended descriptions...'

        warnings = tracker.warnings
        total = warnings.length

        # Update warnings with LLM analysis
        warnings.each_with_index do |warning, index|
          unless @quiet or options[:report_progress] == false
            $stderr.print " #{index}/#{total} warnings processed\r"
          end

          if set_analysis
            warning.llm_analysis = llm.analyze_warning(warning)

            if disclaimer
              warning.llm_analysis << "\n\n" << disclaimer
            end
          else
            warning.message << "\n\n" << llm.analyze_warning(warning)

            if disclaimer
              warning.message << "\n\n" << disclaimer
            end
          end
        end

        # Move message to end of the warning output for text report
        # because LLMs can be quite wordy
        tracker.options[:text_fields] ||= [:confidence, :category, :check, :code, :file, :line, :message]
        tracker.options[:output_formats] = output_formats

        if output_files
          notify "Generating report..."

          write_report_to_files tracker, output_files
        elsif print_report
          notify "Generating report..."

          write_report_to_formats tracker, output_formats
        end

        tracker
      else
        raise 'Missing LLM configuration'
      end
    end
  end
end
