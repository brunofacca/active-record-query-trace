$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'active_record_query_trace/version'

Gem::Specification.new do |gem|
  gem.name          = 'active_record_query_trace'
  gem.version       = ActiveRecordQueryTrace::VERSION
  gem.summary       = 'Print stack trace of all queries to the Rails log. Helpful to find where queries are being executed in your application.'
  gem.description   = gem.summary
  gem.authors       = ['Cody Caughlan', 'Bruno Facca']
  gem.email         = 'bruno@facca.info'
  gem.homepage      = 'https://github.com/brunofacca/active-record-query-trace'
  gem.files         = Dir['lib/**/*']
  gem.license       = 'MIT'
end
