# LLM-based Descriptions for Brakeman Warnings

This library adds LLM-based descriptions to Brakeman warnings, using the [RubyLLM library](https://rubyllm.com/).

You will need to connect up to an LLM provider.

The intent is primarily to provide expanded descriptions using context from the warnings themselves.

## Installation

`gem install brakeman-llm`

## Running

Use `brakeman-llm` to run. All regular Brakeman options should work.

### Options

Use the `llm-` prefixed options to configure RubyLLM under the hood.

* `--llm-provider` - LLM provider (Ollama, OpenAI, Anthropic, etc.)
* `--llm-model` - LLM model 
* `--llm-api-base` - For Ollama, the URL to use
* `--llm-disclaimer` - Change the disclaimer added to LLM-generated descriptions. Use `--llm-no-disclaimer` to remove entirely.

### Example

Using Ollama locally:

`brakeman-llm --llm-provider ollama --llm-model gemma3:4b --llm-api-base http://localhost:11434/v1`

Using Anthropic Claude:

`brakeman-llm --llm-provider anthropic --llm-model claude-3-5-sonnet-20240620 --llm-api-key CLAUDE_API_KEY`

## Configuration

Brakeman-LLM can also be configured in the standard Brakeman YAML file (e.g. in `config/brakeman.yaml`):

```yaml
---
llm:
  provider: ollama
  api_base: http://localhost:11434/v1
  model: gemma3:4b
```

Additional configuration options:

* `prompt` - Set the prompt sent to the LLM for each warning. The Brakeman warning will always be appended as JSON.
* `instructions` - Override the instructions for the LLM. See [RubyLLM Instructions](https://rubyllm.com/guides/chat#guiding-the-ai-with-instructions) for details.

All other keys under `llm` will be sent directly to the RubyLLM library. See [RubyLLM Configuration](https://rubyllm.com/configuration) for more.

For example:

```yaml
---
llm:
  request_timeout: 300  
```

## Limitations

For JSON output, the LLM-generated descriptions are added in the `llm_analysis` key.

For all other formats, the LLM-generated descriptions are added to the warning message.

## License

The gem is available as open source under the terms of the MIT License.
