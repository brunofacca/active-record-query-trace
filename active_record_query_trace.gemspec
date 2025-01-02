# frozen_string_literal: true

require_relative 'lib/active_record_query_trace/version'

Gem::Specification.new do |spec|
  spec.name          = 'active_record_query_trace'
  spec.version       = ActiveRecordQueryTrace::VERSION
  spec.authors       = ['Cody Caughlan', 'Bruno Facca']
  spec.email         = 'bruno@facca.info'

  spec.summary       = 'Print stack trace of all DB queries to the Rails log. ' \
                       'Helpful to find where queries are being executed in your application.'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/brunofacca/active-record-query-trace'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.7', '< 3.5'

  spec.metadata['homepage_uri'] = spec.homepage

  spec.files = Dir['lib/**/*']
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '>= 6.0.0'

  spec.add_development_dependency 'rake', '~> 13.0'

  spec.add_development_dependency 'debug', '~> 1.8'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.55'
  spec.add_development_dependency 'rubocop-performance', '~> 1.18'
  spec.add_development_dependency 'rubocop-rails', '~> 2.20'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.22'
  spec.add_development_dependency 'simplecov', '>= 0.22.0'
end
