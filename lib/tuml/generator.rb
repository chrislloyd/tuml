require 'json'
require 'colored'

class Tuml
  class Generator

    def initialize(ctx)
      @ctx = ctx
    end

    def compile(node)
      type = node.first
      send("on_#{type}", *node[1..-1])
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
      if var = @ctx.find("block:#{name}")
        if var.is_a?(Array)
          var.map do |ctx|
            ctx.parent = @ctx
            @ctx = ctx

            result = compile(body)

            @ctx = ctx.parent

            result
          end.join
        else
          compile(body)
        end
      end
    end

    def on_tag name, attrs={}
      @ctx.find(name)
    end

    def on_esc type, tag
      send "esc_#{type}", compile(tag)
    end

    def on_cond type, name, body
      ''
      # var = @ctx.find(name)
      # if (type == :if && var) || (type == :ifnot && !var)
      #   compile(body)
      # else
      #   ''
      # end
    end

    def on_text label
      @ctx.find(label)
    end

    def on_color label
      @ctx.find(label)
    end

    def on_font label
      @ctx.find(label)
    end

    def on_image label
      @ctx.find(label)
    end

    def on_lang label
      @ctx.find(label)
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
