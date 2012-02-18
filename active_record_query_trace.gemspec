Gem::Specification.new do |s|
  s.name          = 'active_record_query_trace'
  s.version       = '1.0'
  s.date          = '2011-11-19'
  s.summary       = "Print stack trace of all queries to the Rails log. Helpful to find where queries are being executed in your application."
  s.description   = s.summary
  s.authors       = ["Cody Caughlan"]
  s.email         = 'toolbag@gmail.com'
  s.files         = ["README.md", "lib/active_record_query_trace.rb"]
  s.homepage      = 'https://github.com/ruckus/active-record-query-trace'
  s.require_paths = ['lib']
  s.has_rdoc      = false
end