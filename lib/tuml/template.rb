require 'tuml/parser'
require 'tuml/generator'

class Tuml
  class Template
    attr_reader :source

    def initialize(source)
      @source = source
    end

    def render(context, src = @source)
      Generator.new(context).compile(tokens(src))
    end

    def tokens(src = @source)
      Parser.new(src).compile
    end

    # def available_options(tuml)
    #   Nokogiri::HTML(tuml)
    #     .css('meta')
    #     .select {|node| node[:name] =~ /^(color|font|if|text|image):(.+)$/}
    #     .each_with_object({}) do |node, opts|
    #       type, label = node[:name].split(':')
    #       opts[[type.to_sym, label]] = node[:content]
    #     end
    # end

    # /               -> Page(0)
    # /page/:n        -> Page(n)
    # /post/:id       -> Permalink(id)
    # /search/foo+bar -> Search
    # /ask            -> Ask
    # /submit         -> Submit
    # /*              -> Page(url)

  end
end
