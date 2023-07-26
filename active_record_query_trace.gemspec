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
  spec.required_ruby_version = '>= 2.7', '< 3.4'

  spec.metadata['homepage_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .travis.yml appveyor Gemfile])
    end
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '>= 6.0.0'
end
