require 'nokogiri'

module Tuml
  class Template

    def initialize(data)
      @data = data
      @context = []
    end

    def render(url, src, options={})
      parser = Paser.new(source)
      parser.parse

      Generator.new parser.ast, self
    end

    def lookup var, attrs={}
      'Foo'
    end

    def lookup_

    # def available_options(tuml)
    #   Nokogiri::HTML(tuml)
    #     .css('meta')
    #     .select {|node| node[:name] =~ /^(color|font|if|text|image):(.+)$/}
    #     .each_with_object({}) do |node, opts|
    #       type, label = node[:name].split(':')
    #       opts[[type.to_sym, label]] = node[:content]
    #     end
    # end
  end
end


