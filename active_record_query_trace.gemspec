$:.unshift File.expand_path("../lib", __FILE__)
require 'version'

Gem::Specification.new do |gem|
  gem.name          = 'active_record_query_trace'
  gem.version       = ActiveRecordQueryTrace::VERSION
  gem.summary       = "Print stack trace of all queries to the Rails log. Helpful to find where queries are being executed in your application."
  gem.description   = gem.summary
  gem.authors       = ["Cody Caughlan"]
  gem.email         = 'toolbag@gmail.com'
  gem.homepage      = 'https://github.com/ruckus/active-record-query-trace'
  gem.files         = Dir["**/*"]
  gem.license       = 'MIT'
end