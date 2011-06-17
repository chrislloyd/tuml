require 'rake/clean'
require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = "test/test_*.rb"
end

CLOBBER.add 'lib/tuml/parser.rb'

file 'lib/tuml/parser.rb' do |f|
  sh "bundle exec kpeg --force --stand-alone --output #{f.name} lib/tuml/tuml.kpeg"
end
