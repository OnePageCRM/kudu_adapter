# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'impala_adapter/version'

Gem::Specification.new do |s|
  s.name = 'impala_adapter'
  s.version = ImpalaAdapter::VERSION
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 2.4.0'
  s.authors = ['Paweł Smoliński', 'OnePageCRM']
  s.licenses = ['MIT']
  s.email = 'devteam@onepagecrm.com'
  s.homepage = 'https://github.com/OnePageCRM/impala_adapter'
  s.summary = "ActiveRecord adapter for Cloudera's Impala database"
  s.description = "ActiveRecord adapter for Cloudera's Impala database"
  s.email = 'devteam@onepagecrm.com'

  s.add_runtime_dependency('arel', ['~> 8.0'])
  s.add_runtime_dependency('activerecord', ['~> 5.1.0'])
  s.add_runtime_dependency('impala', ['~> 0.5.1'])

  s.add_development_dependency('bundler')

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.require_paths = ['lib']
end
