# frozen_string_literal: true

source 'http://rubygems.org'
gemspec

# Travis CI sets the RAILS_VERSION environment variable (see .travis.yml).
rails_version =
  case ENV['RAILS_VERSION']
  when 'master'
    { github: 'rails/rails' }
  when nil
    # Default version, required for running tests locally without setting ENV['RAILS_VERSION'].
    '>= 5.2.2'
  else
    "~> #{ENV['RAILS_VERSION']}"
  end

gem 'rails', rails_version
