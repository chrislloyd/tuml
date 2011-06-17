# encoding: utf-8
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'tuml/version'

spec = Gem::Specification.new do |s|
  s.name = 'tuml'
  s.summary = 'Tumblr Markup Language Parser'
  s.author = 'Chris Lloyd'
  s.email  = 'christopher.lloyd@gmail.com'
  s.version = Tuml::VERSION
  s.files = Dir['{lib,test}/**/*'] + ['Gemfile', 'Rakefile']

  s.add_dependency 'nokogiri', '>= 1.4'
  s.add_development_dependency 'kpeg', '>= 0.8'
end
