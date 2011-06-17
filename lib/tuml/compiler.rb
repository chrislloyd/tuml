require 'json'

module Tuml
  class Compiler

    def initialize(context)
      @context = context
    end

    def compile node
      type = node.shift
      send("on_#{type}", *node)
    end

    def on_multi *parts
      parts.map {|part| compile(part)}.join
    end

    def on_static text
      text
    end

    def on_noop
      ''
    end

    def on_block name, body
      var = @context.lookup(name)
      return unless var

      [*var].map do |ctx|
        @context.push ctx
        result = compile(body)
        @context.pop
        result
      end.join
    end

    def on_var name, attrs={}
      @context.lookup name, attrs
    end

    def on_esc type, tag
      send "esc_#{type}", compile(tag)
    end

    def on_cond type, name, body
      var = @context.lookup name
      if (type == :if && var) || (type == :ifnot && !var)
        compile(body)
      end
        ''
      end
    end

    def on_text label
      @context.lookup_text label
    end

    def on_color label
      @context.lookup_color label
    end

    def on_font label
      @context.lookup_font label
    end

    def on_image label
      @context.lookup_image label
    end

    def on_lang label
      @context.lookup_lang label
    end


    # Escapes

    def esc_js str
      str.to_json
    end

    # TODO
    def esc_jsplaintext str
      str
    end

    # TODO
    def esc_plaintext str
      str
    end

    # TODO
    def esc_urlencoded str
      str
    end

  end
end
