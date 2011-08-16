class Tuml
  class Context

    attr_reader :data

    attr_accessor :parent

    def self.prototype
      @prototype ||= {}
    end

    def self.tag(name, &blk)
      prototype[name] = block_given? ? blk : -> { data[name]}
    end

    def self.block(name, klass=nil, &blk)
      prototype["block:#{name}"] = blk
    end


    def initialize(data)
      @data = data
    end

    def find(name)
      method = self.class.prototype[name]
      if method
        instance_exec &method
      elsif parent
        parent.find(name)
      end
    end

    # TODO: Rename this method
    def raw_block(name)
      data["block:#{name}"] || []
    end

  end
end
