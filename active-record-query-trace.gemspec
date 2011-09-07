# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "active-record-query-trace"
  s.version     = '0.1.0'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Cody Caughlan"]
  s.email       = ["toolbag@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Query Backtrace for ActiveRecord}
  s.description = %q{Query Backtrace for ActiveRecord}

  #s.rubyforge_project = "grassdb"

  # Files
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
