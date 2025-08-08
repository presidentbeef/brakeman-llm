# LLM Sprinkles for Brakeman

This library adds LLM-based descriptions to Brakeman warnings using the [RubyLLM library](https://rubyllm.com/).

You will need to connect it up to an LLM provider (Ollama, Anthropic, etc).

## Example

*Before*

```
Confidence: High
Category: Weak Cryptography
Check: WeakRSAKey
Message: Use of padding mode PKCS1 (default if not specified), which is known to be insecure. Use OAEP instead
Code: OpenSSL::PKey::RSA.new("grab the public 4096 bit key").public_encrypt(payload.to_json)
File: lib/some_lib.rb
Line: 4

```

*After*

```
Confidence: High
Category: Weak Cryptography
Check: WeakRSAKey
Code: OpenSSL::PKey::RSA.new("grab the public 4096 bit key").public_encrypt(payload.to_json)
File: lib/some_lib.rb
Line: 4
Message: Use of padding mode PKCS1 (default if not specified), which is known to be insecure. Use OAEP instead

The Brakeman security warning identifies a Weak Cryptography vulnerability in the Ruby on Rails application. Specifically, it points out the use of an insecure padding mode (PKCS1) in RSA encryption.

The vulnerability occurs in the file "lib/some_lib.rb" on line 4, within the SomeLib class's some_rsa_encrypting method. The code in question is using OpenSSL::PKey::RSA to perform public key encryption on a JSON payload.

The main issue is that the encryption is using the default padding mode, which is PKCS1. This padding scheme is known to be vulnerable to certain types of attacks, particularly padding oracle attacks. These attacks can potentially allow an attacker to decrypt the encrypted data or even recover the private key in some scenarios.

To address this vulnerability, the recommendation is to use OAEP (Optimal Asymmetric Encryption Padding) instead of PKCS1. OAEP is a more secure padding scheme that is resistant to the vulnerabilities associated with PKCS1.

To fix this issue:

1. Update the encryption code to explicitly use OAEP padding. In Ruby, this can be done by passing the appropriate option to the public_encrypt method:

   ```ruby
   OpenSSL::PKey::RSA.new("grab the public 4096 bit key").public_encrypt(payload.to_json, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)
   ```

2. Ensure that the corresponding decryption code also uses OAEP padding:

   ```ruby
   private_key.private_decrypt(encrypted_data, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)
   ```

3. Review all instances of RSA encryption in the codebase to ensure consistent use of secure padding schemes.

4. Consider using higher-level cryptographic libraries or gems that implement secure defaults and best practices, reducing the risk of such vulnerabilities.

By implementing these changes, the application will use a more secure padding scheme for RSA encryption, significantly reducing the risk of attacks exploiting weaknesses in the PKCS1 padding mode.

(The above message is auto-generated and may contain errors.)
```

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

### Example Commands

Using Ollama locally:

`brakeman-llm --llm-provider ollama --llm-model gemma3:4b --llm-api-base http://localhost:11434/v1`

Using Anthropic Claude:

`brakeman-llm --llm-provider anthropic --llm-model claude-3-5-sonnet-20240620 --llm-api-key YOUR_CLAUDE_API_KEY`

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
