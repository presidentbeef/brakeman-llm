Gem::Specification.new do |s|
  s.name = 'brakeman-llm'
  s.version = '0.0.2'

  s.authors = ['Justin Collins']
  s.email = 'gem@brakeman.org'
  s.homepage = 'https://github.com/presidentbeef/brakeman-llm'

  s.summary = 'Enhance Brakeman warnings with LLM-based descriptions'
  s.description = 'Brakeman detects security vulnerabilities in Ruby on Rails applications via static analysis.'

  s.executables = 'brakeman-llm'
  s.files = ['bin/brakeman-llm', 'lib/brakeman-llm.rb'] + Dir.glob('docs/warning_types/*/**.markdown')
  s.license = 'MIT'
  s.required_ruby_version = '>= 3.1.0'

  s.metadata = {
    'source_code_uri'   => 'https://github.com/presidentbeef/brakeman-llm',
  }

  s.add_dependency('brakeman', '>= 7.0')
  s.add_dependency('ruby_llm', '>= 1.6', '<= 2.0')
end
