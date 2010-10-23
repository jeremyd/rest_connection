require 'rubygems'
require 'jeweler'
require 'spec/rake/spectask'

BASE_DIR = File.expand_path(File.dirname(__FILE__))

Jeweler::Tasks.new do |gemspec|
  gemspec.name = "rest_connection"
  gemspec.summary = "lib for restful connections to the rightscale api"
  gemspec.description = "provides rest_connection"
  gemspec.email = "jeremy@rubyonlinux.org"
  gemspec.homepage = "http://github.com/jeremyd/rest_connection"
  gemspec.authors = ["Jeremy Deininger"]
  gemspec.add_dependency('activesupport')
  gemspec.add_dependency('net-ssh')
  gemspec.add_dependency('json')
end
Jeweler::GemcutterTasks.new

desc "Run spec tests"
task :spec => 'spec:unit'

namespace :spec do
  desc "Run unit tests"
  Spec::Rake::SpecTask.new(:unit) do |t|
    t.spec_opts = ['--options', "\"#{BASE_DIR}/spec/spec.opts\""]
    unit_tests = Dir['spec/rest_connection/*_spec.rb']
    t.spec_files = unit_tests
  end
end