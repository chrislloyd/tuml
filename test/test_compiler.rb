require 'minitest/autorun'
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'tuml/compiler'

describe 'Tuml::Compiler' do

  def self.compiles desc, &blk
    it "compiles #{desc}", &blk
  end

  before do
    @context = Class.new do
      def lookup arg
        arg
      end
    end.new
    @compiler = Tuml::Compiler.new(@context)
  end

  compiles 'static text' do
    @compiler.compile([:static, 'Foo']).must_equal 'Foo'
  end

  compiles 'noops' do
    @compiler.compile([:noop]).must_equal ''
  end

  compiles 'multi blocks' do
    @compiler.compile([:multi, [:static, 'Foo'], [:static, 'Bar']])
      .must_equal 'FooBar'
  end

  compiles 'variables' do
    @compiler.compile([:var, 'Foo']).must_equal 'Bar'
  end

  compiles 'true blocks' do
    # @context.lookup('Foo') { true }
    @compiler.compile([:block, 'Foo', [:multi, [:static, 'Bar']]])
      .must_equal 'Foo'
  end

  compiles 'false blocks' do
    # @context.lookup()
  end

  # compiles 'blocks' do
  #   # @context.lookup('Foo') { true }
  #
  #   @compiler.compile [:block, 'Foo', [:static]]
  #
  # end

end
