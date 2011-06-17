class Tuml::Parser
# STANDALONE START
    def setup_parser(str, debug=false)
      @string = str
      @pos = 0
      @memoizations = Hash.new { |h,k| h[k] = {} }
      @result = nil
      @failed_rule = nil
      @failing_rule_offset = -1

      setup_foreign_grammar
    end

    # This is distinct from setup_parser so that a standalone parser
    # can redefine #initialize and still have access to the proper
    # parser setup code.
    #
    def initialize(str, debug=false)
      setup_parser(str, debug)
    end

    attr_reader :string
    attr_reader :failing_rule_offset
    attr_accessor :result, :pos

    # STANDALONE START
    def current_column(target=pos)
      if c = string.rindex("\n", target-1)
        return target - c - 1
      end

      target + 1
    end

    def current_line(target=pos)
      cur_offset = 0
      cur_line = 0

      string.each_line do |line|
        cur_line += 1
        cur_offset += line.size
        return cur_line if cur_offset >= target
      end

      -1
    end

    def lines
      lines = []
      string.each_line { |l| lines << l }
      lines
    end

    #

    def get_text(start)
      @string[start..@pos-1]
    end

    def show_pos
      width = 10
      if @pos < width
        "#{@pos} (\"#{@string[0,@pos]}\" @ \"#{@string[@pos,width]}\")"
      else
        "#{@pos} (\"... #{@string[@pos - width, width]}\" @ \"#{@string[@pos,width]}\")"
      end
    end

    def failure_info
      l = current_line @failing_rule_offset
      c = current_column @failing_rule_offset

      if @failed_rule.kind_of? Symbol
        info = self.class::Rules[@failed_rule]
        "line #{l}, column #{c}: failed rule '#{info.name}' = '#{info.rendered}'"
      else
        "line #{l}, column #{c}: failed rule '#{@failed_rule}'"
      end
    end

    def failure_caret
      l = current_line @failing_rule_offset
      c = current_column @failing_rule_offset

      line = lines[l-1]
      "#{line}\n#{' ' * (c - 1)}^"
    end

    def failure_character
      l = current_line @failing_rule_offset
      c = current_column @failing_rule_offset
      lines[l-1][c-1, 1]
    end

    def failure_oneline
      l = current_line @failing_rule_offset
      c = current_column @failing_rule_offset

      char = lines[l-1][c-1, 1]

      if @failed_rule.kind_of? Symbol
        info = self.class::Rules[@failed_rule]
        "@#{l}:#{c} failed rule '#{info.name}', got '#{char}'"
      else
        "@#{l}:#{c} failed rule '#{@failed_rule}', got '#{char}'"
      end
    end

    class ParseError < RuntimeError
    end

    def raise_error
      raise ParseError, failure_oneline
    end

    def show_error(io=STDOUT)
      error_pos = @failing_rule_offset
      line_no = current_line(error_pos)
      col_no = current_column(error_pos)

      io.puts "On line #{line_no}, column #{col_no}:"

      if @failed_rule.kind_of? Symbol
        info = self.class::Rules[@failed_rule]
        io.puts "Failed to match '#{info.rendered}' (rule '#{info.name}')"
      else
        io.puts "Failed to match rule '#{@failed_rule}'"
      end

      io.puts "Got: #{string[error_pos,1].inspect}"
      line = lines[line_no-1]
      io.puts "=> #{line}"
      io.print(" " * (col_no + 3))
      io.puts "^"
    end

    def set_failed_rule(name)
      if @pos > @failing_rule_offset
        @failed_rule = name
        @failing_rule_offset = @pos
      end
    end

    attr_reader :failed_rule

    def match_string(str)
      len = str.size
      if @string[pos,len] == str
        @pos += len
        return str
      end

      return nil
    end

    def scan(reg)
      if m = reg.match(@string[@pos..-1])
        width = m.end(0)
        @pos += width
        return true
      end

      return nil
    end

    if "".respond_to? :getbyte
      def get_byte
        if @pos >= @string.size
          return nil
        end

        s = @string.getbyte @pos
        @pos += 1
        s
      end
    else
      def get_byte
        if @pos >= @string.size
          return nil
        end

        s = @string[@pos]
        @pos += 1
        s
      end
    end

    def parse(rule=nil)
      if !rule
        _root ? true : false
      else
        # This is not shared with code_generator.rb so this can be standalone
        method = rule.gsub("-","_hyphen_")
        __send__("_#{method}") ? true : false
      end
    end

    class LeftRecursive
      def initialize(detected=false)
        @detected = detected
      end

      attr_accessor :detected
    end

    class MemoEntry
      def initialize(ans, pos)
        @ans = ans
        @pos = pos
        @uses = 1
        @result = nil
      end

      attr_reader :ans, :pos, :uses, :result

      def inc!
        @uses += 1
      end

      def move!(ans, pos, result)
        @ans = ans
        @pos = pos
        @result = result
      end
    end

    def external_invoke(other, rule, *args)
      old_pos = @pos
      old_string = @string

      @pos = other.pos
      @string = other.string

      begin
        if val = __send__(rule, *args)
          other.pos = @pos
          other.result = @result
        else
          other.set_failed_rule "#{self.class}##{rule}"
        end
        val
      ensure
        @pos = old_pos
        @string = old_string
      end
    end

    def apply_with_args(rule, *args)
      memo_key = [rule, args]
      if m = @memoizations[memo_key][@pos]
        m.inc!

        prev = @pos
        @pos = m.pos
        if m.ans.kind_of? LeftRecursive
          m.ans.detected = true
          return nil
        end

        @result = m.result

        return m.ans
      else
        lr = LeftRecursive.new(false)
        m = MemoEntry.new(lr, @pos)
        @memoizations[memo_key][@pos] = m
        start_pos = @pos

        ans = __send__ rule, *args

        m.move! ans, @pos, @result

        # Don't bother trying to grow the left recursion
        # if it's failing straight away (thus there is no seed)
        if ans and lr.detected
          return grow_lr(rule, args, start_pos, m)
        else
          return ans
        end

        return ans
      end
    end

    def apply(rule)
      if m = @memoizations[rule][@pos]
        m.inc!

        prev = @pos
        @pos = m.pos
        if m.ans.kind_of? LeftRecursive
          m.ans.detected = true
          return nil
        end

        @result = m.result

        return m.ans
      else
        lr = LeftRecursive.new(false)
        m = MemoEntry.new(lr, @pos)
        @memoizations[rule][@pos] = m
        start_pos = @pos

        ans = __send__ rule

        m.move! ans, @pos, @result

        # Don't bother trying to grow the left recursion
        # if it's failing straight away (thus there is no seed)
        if ans and lr.detected
          return grow_lr(rule, nil, start_pos, m)
        else
          return ans
        end

        return ans
      end
    end

    def grow_lr(rule, args, start_pos, m)
      while true
        @pos = start_pos
        @result = m.result

        if args
          ans = __send__ rule, *args
        else
          ans = __send__ rule
        end
        return nil unless ans

        break if @pos <= m.pos

        m.move! ans, @pos, @result
      end

      @result = m.result
      @pos = m.pos
      return m.ans
    end

    class RuleInfo
      def initialize(name, rendered)
        @name = name
        @rendered = rendered
      end

      attr_reader :name, :rendered
    end

    def self.rule_info(name, rendered)
      RuleInfo.new(name, rendered)
    end

    #


  def initialize *args
    setup_parser *args
    @stack = []
  end

  def close_block collection, name
    collection << [:block, :close, name]
  end

  def ast
    @ast ||= begin
      stack = [[:multi]]

      # Close any open tags
      @stack.reverse.each {|ctx| close_block @tokens, ctx}

      # Constructs a sequence of nested blocks from the token sequence.
      @tokens.inject([[:multi]]) do |stack, node|
        case node[0]
        when :block, :cond
          case node[1]
          when :open
            body = [:multi]
            stack.last << [node[0], *node[2..-1], body]
            stack << body

          when :close
            body = stack.pop
          end

        else
          stack.last << node
        end

        stack
      end.first

    end
  end


  def setup_foreign_grammar; end

  # eof = !.
  def _eof
    _save = self.pos
    _tmp = get_byte
    _tmp = _tmp ? nil : true
    self.pos = _save
    set_failed_rule :_eof unless _tmp
    return _tmp
  end

  # st = "{"
  def _st
    _tmp = match_string("{")
    set_failed_rule :_st unless _tmp
    return _tmp
  end

  # et = "}"
  def _et
    _tmp = match_string("}")
    set_failed_rule :_et unless _tmp
    return _tmp
  end

  # sep = ":"
  def _sep
    _tmp = match_string(":")
    set_failed_rule :_sep unless _tmp
    return _tmp
  end

  # attr_sep = "="
  def _attr_sep
    _tmp = match_string("=")
    set_failed_rule :_attr_sep unless _tmp
    return _tmp
  end

  # space = (" " | "\t")
  def _space

    _save = self.pos
    while true # choice
      _tmp = match_string(" ")
      break if _tmp
      self.pos = _save
      _tmp = match_string("\t")
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_space unless _tmp
    return _tmp
  end

  # sp = space+
  def _sp
    _save = self.pos
    _tmp = apply(:_space)
    if _tmp
      while true
        _tmp = apply(:_space)
        break unless _tmp
      end
      _tmp = true
    else
      self.pos = _save
    end
    set_failed_rule :_sp unless _tmp
    return _tmp
  end

  # - = space*
  def __hyphen_
    while true
      _tmp = apply(:_space)
      break unless _tmp
    end
    _tmp = true
    set_failed_rule :__hyphen_ unless _tmp
    return _tmp
  end

  # quo = "\""
  def _quo
    _tmp = match_string("\"")
    set_failed_rule :_quo unless _tmp
    return _tmp
  end

  # escape_type = < ("URLEncoded" | "JSPlaintext" | "Plaintext" | "JS") > { text.downcase }
  def _escape_type

    _save = self.pos
    while true # sequence
      _text_start = self.pos

      _save1 = self.pos
      while true # choice
        _tmp = match_string("URLEncoded")
        break if _tmp
        self.pos = _save1
        _tmp = match_string("JSPlaintext")
        break if _tmp
        self.pos = _save1
        _tmp = match_string("Plaintext")
        break if _tmp
        self.pos = _save1
        _tmp = match_string("JS")
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  text.downcase ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_escape_type unless _tmp
    return _tmp
  end

  # opt_type = < ("color" | "image" | "font" | "text" | "lang") > { text.downcase }
  def _opt_type

    _save = self.pos
    while true # sequence
      _text_start = self.pos

      _save1 = self.pos
      while true # choice
        _tmp = match_string("color")
        break if _tmp
        self.pos = _save1
        _tmp = match_string("image")
        break if _tmp
        self.pos = _save1
        _tmp = match_string("font")
        break if _tmp
        self.pos = _save1
        _tmp = match_string("text")
        break if _tmp
        self.pos = _save1
        _tmp = match_string("lang")
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  text.downcase ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_opt_type unless _tmp
    return _tmp
  end

  # block_type = "/"?:close "block" { close ? :close : :open }
  def _block_type

    _save = self.pos
    while true # sequence
      _save1 = self.pos
      _tmp = match_string("/")
      @result = nil unless _tmp
      unless _tmp
        _tmp = true
        self.pos = _save1
      end
      close = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string("block")
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  close ? :close : :open ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_block_type unless _tmp
    return _tmp
  end

  # bool_type = < ("IfNot" | "If") > { text.downcase }
  def _bool_type

    _save = self.pos
    while true # sequence
      _text_start = self.pos

      _save1 = self.pos
      while true # choice
        _tmp = match_string("IfNot")
        break if _tmp
        self.pos = _save1
        _tmp = match_string("If")
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  text.downcase ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_bool_type unless _tmp
    return _tmp
  end

  # name = < /[a-zA-Z][0-9a-zA-Z-]*/ > { text }
  def _name

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = scan(/\A(?-mix:[a-zA-Z][0-9a-zA-Z-]*)/)
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  text ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_name unless _tmp
    return _tmp
  end

  # label = < (!et .)+ > { text }
  def _label

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _save1 = self.pos

      _save2 = self.pos
      while true # sequence
        _save3 = self.pos
        _tmp = apply(:_et)
        _tmp = _tmp ? nil : true
        self.pos = _save3
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = get_byte
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      if _tmp
        while true

          _save4 = self.pos
          while true # sequence
            _save5 = self.pos
            _tmp = apply(:_et)
            _tmp = _tmp ? nil : true
            self.pos = _save5
            unless _tmp
              self.pos = _save4
              break
            end
            _tmp = get_byte
            unless _tmp
              self.pos = _save4
            end
            break
          end # end sequence

          break unless _tmp
        end
        _tmp = true
      else
        self.pos = _save1
      end
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  text ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_label unless _tmp
    return _tmp
  end

  # attr_key = < (!attr_sep .)+ > { text }
  def _attr_key

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _save1 = self.pos

      _save2 = self.pos
      while true # sequence
        _save3 = self.pos
        _tmp = apply(:_attr_sep)
        _tmp = _tmp ? nil : true
        self.pos = _save3
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = get_byte
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      if _tmp
        while true

          _save4 = self.pos
          while true # sequence
            _save5 = self.pos
            _tmp = apply(:_attr_sep)
            _tmp = _tmp ? nil : true
            self.pos = _save5
            unless _tmp
              self.pos = _save4
              break
            end
            _tmp = get_byte
            unless _tmp
              self.pos = _save4
            end
            break
          end # end sequence

          break unless _tmp
        end
        _tmp = true
      else
        self.pos = _save1
      end
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  text ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_attr_key unless _tmp
    return _tmp
  end

  # attr_val = quo < (!quo .)+ > quo { text }
  def _attr_val

    _save = self.pos
    while true # sequence
      _tmp = apply(:_quo)
      unless _tmp
        self.pos = _save
        break
      end
      _text_start = self.pos
      _save1 = self.pos

      _save2 = self.pos
      while true # sequence
        _save3 = self.pos
        _tmp = apply(:_quo)
        _tmp = _tmp ? nil : true
        self.pos = _save3
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = get_byte
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      if _tmp
        while true

          _save4 = self.pos
          while true # sequence
            _save5 = self.pos
            _tmp = apply(:_quo)
            _tmp = _tmp ? nil : true
            self.pos = _save5
            unless _tmp
              self.pos = _save4
              break
            end
            _tmp = get_byte
            unless _tmp
              self.pos = _save4
            end
            break
          end # end sequence

          break unless _tmp
        end
        _tmp = true
      else
        self.pos = _save1
      end
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_quo)
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  text ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_attr_val unless _tmp
    return _tmp
  end

  # attr = sp attr_key:key attr_sep attr_val:val { [key, val] }
  def _attr

    _save = self.pos
    while true # sequence
      _tmp = apply(:_sp)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_attr_key)
      key = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_attr_sep)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_attr_val)
      val = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  [key, val] ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_attr unless _tmp
    return _tmp
  end

  # var_tag = name:name attr*:attrs {     [if attrs.empty?       [:tag, name]     else       [:tag, name, Hash[attrs]]     end]   }
  def _var_tag

    _save = self.pos
    while true # sequence
      _tmp = apply(:_name)
      name = @result
      unless _tmp
        self.pos = _save
        break
      end
      _ary = []
      while true
        _tmp = apply(:_attr)
        _ary << @result if _tmp
        break unless _tmp
      end
      _tmp = true
      @result = _ary
      attrs = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; 
    [if attrs.empty?
      [:tag, name]
    else
      [:tag, name, Hash[attrs]]
    end]
  ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_var_tag unless _tmp
    return _tmp
  end

  # escaped_var_tag = escape_type:type var_tag:v { [[:esc, type.to_sym, *v]] }
  def _escaped_var_tag

    _save = self.pos
    while true # sequence
      _tmp = apply(:_escape_type)
      type = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_var_tag)
      v = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  [[:esc, type.to_sym, *v]] ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_escaped_var_tag unless _tmp
    return _tmp
  end

  # opt_tag = opt_type:opt sep label:label { [[opt.to_sym, label]] }
  def _opt_tag

    _save = self.pos
    while true # sequence
      _tmp = apply(:_opt_type)
      opt = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_sep)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_label)
      label = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  [[opt.to_sym, label]] ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_opt_tag unless _tmp
    return _tmp
  end

  # block = block_type:type sep name:name {     result = []     if idx = @stack.rindex(name)       # Close all the blocks leading up to current one       (@stack.length - 1 - idx).times do         close_block result, @stack.pop       end        # Force close the block       type = :close       @stack.pop     else       @stack << name     end      result << [:block, type, name]     result   }
  def _block

    _save = self.pos
    while true # sequence
      _tmp = apply(:_block_type)
      type = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_sep)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_name)
      name = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; 
    result = []
    if idx = @stack.rindex(name)
      # Close all the blocks leading up to current one
      (@stack.length - 1 - idx).times do
        close_block result, @stack.pop
      end

      # Force close the block
      type = :close
      @stack.pop
    else
      @stack << name
    end

    result << [:block, type, name]
    result
  ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_block unless _tmp
    return _tmp
  end

  # cond = block_type:type sep bool_type:bool_type name:name { [[:cond, type, bool_type.to_sym, name]] }
  def _cond

    _save = self.pos
    while true # sequence
      _tmp = apply(:_block_type)
      type = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_sep)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_bool_type)
      bool_type = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_name)
      name = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  [[:cond, type, bool_type.to_sym, name]] ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_cond unless _tmp
    return _tmp
  end

  # tag = st (cond | block | opt_tag | escaped_var_tag | var_tag):body et { body }
  def _tag

    _save = self.pos
    while true # sequence
      _tmp = apply(:_st)
      unless _tmp
        self.pos = _save
        break
      end

      _save1 = self.pos
      while true # choice
        _tmp = apply(:_cond)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_block)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_opt_tag)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_escaped_var_tag)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_var_tag)
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      body = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_et)
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  body ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_tag unless _tmp
    return _tmp
  end

  # noop = st (!et .)+ et { [[:noop]] }
  def _noop

    _save = self.pos
    while true # sequence
      _tmp = apply(:_st)
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos

      _save2 = self.pos
      while true # sequence
        _save3 = self.pos
        _tmp = apply(:_et)
        _tmp = _tmp ? nil : true
        self.pos = _save3
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = get_byte
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      if _tmp
        while true

          _save4 = self.pos
          while true # sequence
            _save5 = self.pos
            _tmp = apply(:_et)
            _tmp = _tmp ? nil : true
            self.pos = _save5
            unless _tmp
              self.pos = _save4
              break
            end
            _tmp = get_byte
            unless _tmp
              self.pos = _save4
            end
            break
          end # end sequence

          break unless _tmp
        end
        _tmp = true
      else
        self.pos = _save1
      end
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_et)
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  [[:noop]] ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_noop unless _tmp
    return _tmp
  end

  # static = < (!tag .)+ > { [[:static, text]] }
  def _static

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _save1 = self.pos

      _save2 = self.pos
      while true # sequence
        _save3 = self.pos
        _tmp = apply(:_tag)
        _tmp = _tmp ? nil : true
        self.pos = _save3
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = get_byte
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      if _tmp
        while true

          _save4 = self.pos
          while true # sequence
            _save5 = self.pos
            _tmp = apply(:_tag)
            _tmp = _tmp ? nil : true
            self.pos = _save5
            unless _tmp
              self.pos = _save4
              break
            end
            _tmp = get_byte
            unless _tmp
              self.pos = _save4
            end
            break
          end # end sequence

          break unless _tmp
        end
        _tmp = true
      else
        self.pos = _save1
      end
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  [[:static, text]] ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_static unless _tmp
    return _tmp
  end

  # sequence = (tag | noop | static)*:groups {     groups.each_with_object([]) do |elms, result|       elms.each {|elm| result << elm}     end   }
  def _sequence

    _save = self.pos
    while true # sequence
      _ary = []
      while true

        _save2 = self.pos
        while true # choice
          _tmp = apply(:_tag)
          break if _tmp
          self.pos = _save2
          _tmp = apply(:_noop)
          break if _tmp
          self.pos = _save2
          _tmp = apply(:_static)
          break if _tmp
          self.pos = _save2
          break
        end # end choice

        _ary << @result if _tmp
        break unless _tmp
      end
      _tmp = true
      @result = _ary
      groups = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; 
    groups.each_with_object([]) do |elms, result|
      elms.each {|elm| result << elm}
    end
  ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_sequence unless _tmp
    return _tmp
  end

  # root = sequence:s eof { @tokens = s }
  def _root

    _save = self.pos
    while true # sequence
      _tmp = apply(:_sequence)
      s = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_eof)
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  @tokens = s ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_root unless _tmp
    return _tmp
  end

  Rules = {}
  Rules[:_eof] = rule_info("eof", "!.")
  Rules[:_st] = rule_info("st", "\"{\"")
  Rules[:_et] = rule_info("et", "\"}\"")
  Rules[:_sep] = rule_info("sep", "\":\"")
  Rules[:_attr_sep] = rule_info("attr_sep", "\"=\"")
  Rules[:_space] = rule_info("space", "(\" \" | \"\\t\")")
  Rules[:_sp] = rule_info("sp", "space+")
  Rules[:__hyphen_] = rule_info("-", "space*")
  Rules[:_quo] = rule_info("quo", "\"\\\"\"")
  Rules[:_escape_type] = rule_info("escape_type", "< (\"URLEncoded\" | \"JSPlaintext\" | \"Plaintext\" | \"JS\") > { text.downcase }")
  Rules[:_opt_type] = rule_info("opt_type", "< (\"color\" | \"image\" | \"font\" | \"text\" | \"lang\") > { text.downcase }")
  Rules[:_block_type] = rule_info("block_type", "\"/\"?:close \"block\" { close ? :close : :open }")
  Rules[:_bool_type] = rule_info("bool_type", "< (\"IfNot\" | \"If\") > { text.downcase }")
  Rules[:_name] = rule_info("name", "< /[a-zA-Z][0-9a-zA-Z-]*/ > { text }")
  Rules[:_label] = rule_info("label", "< (!et .)+ > { text }")
  Rules[:_attr_key] = rule_info("attr_key", "< (!attr_sep .)+ > { text }")
  Rules[:_attr_val] = rule_info("attr_val", "quo < (!quo .)+ > quo { text }")
  Rules[:_attr] = rule_info("attr", "sp attr_key:key attr_sep attr_val:val { [key, val] }")
  Rules[:_var_tag] = rule_info("var_tag", "name:name attr*:attrs {     [if attrs.empty?       [:tag, name]     else       [:tag, name, Hash[attrs]]     end]   }")
  Rules[:_escaped_var_tag] = rule_info("escaped_var_tag", "escape_type:type var_tag:v { [[:esc, type.to_sym, *v]] }")
  Rules[:_opt_tag] = rule_info("opt_tag", "opt_type:opt sep label:label { [[opt.to_sym, label]] }")
  Rules[:_block] = rule_info("block", "block_type:type sep name:name {     result = []     if idx = @stack.rindex(name)       \# Close all the blocks leading up to current one       (@stack.length - 1 - idx).times do         close_block result, @stack.pop       end        \# Force close the block       type = :close       @stack.pop     else       @stack << name     end      result << [:block, type, name]     result   }")
  Rules[:_cond] = rule_info("cond", "block_type:type sep bool_type:bool_type name:name { [[:cond, type, bool_type.to_sym, name]] }")
  Rules[:_tag] = rule_info("tag", "st (cond | block | opt_tag | escaped_var_tag | var_tag):body et { body }")
  Rules[:_noop] = rule_info("noop", "st (!et .)+ et { [[:noop]] }")
  Rules[:_static] = rule_info("static", "< (!tag .)+ > { [[:static, text]] }")
  Rules[:_sequence] = rule_info("sequence", "(tag | noop | static)*:groups {     groups.each_with_object([]) do |elms, result|       elms.each {|elm| result << elm}     end   }")
  Rules[:_root] = rule_info("root", "sequence:s eof { @tokens = s }")
end
