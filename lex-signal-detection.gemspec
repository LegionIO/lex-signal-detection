# frozen_string_literal: true

require_relative 'lib/legion/extensions/signal_detection/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-signal-detection'
  spec.version       = Legion::Extensions::SignalDetection::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Signal Detection'
  spec.description   = "Green & Swets' Signal Detection Theory engine for LegionIO: sensitivity (d') and response bias (criterion) modeling"
  spec.homepage      = 'https://github.com/LegionIO/lex-signal-detection'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-signal-detection'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-signal-detection'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-signal-detection'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-signal-detection/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-signal-detection.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
  spec.add_development_dependency 'legion-gaia'
end
