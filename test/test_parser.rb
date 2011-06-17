require 'minitest/autorun'
require 'kpeg'

KPeg.load File.expand_path('../../lib/tuml/tuml.kpeg', __FILE__), 'TestParser'

describe 'Tuml::Parser' do

  def self.parses label, str='', &blk
    it "parses #{label}" do
      parser = TestParser.new(str)
      unless parser.parse
        parser.raise_error
      end
      blk.call parser.ast
    end
  end

  parses 'nothing', '' do |ast|
    ast.must_equal [:multi]
  end


  # Tags

  parses 'a tag', '{Foo}' do |ast|
    ast.must_equal [:multi, [:tag, 'Foo']]
  end

  parses 'camelcase tag names', '{FooBar}' do |ast|
    ast.must_equal [:multi, [:tag, 'FooBar']]
  end

  parses 'static text', 'Foo' do |ast|
    ast.must_equal [:multi, [:static, 'Foo']]
  end

  parses 'static text and tags', 'Foo{Bar}Baz' do |ast|
    ast.must_equal [:multi, [:static, 'Foo'],
                            [:tag, 'Bar'],
                            [:static, 'Baz']]
  end

  parses 'tag names with numbers and dashes', '{Photo-500}' do |ast|
    ast.must_equal [:multi, [:tag, 'Photo-500']]
  end

  # parses 'tags with attributes', "{Foo bar=baz}" do |ast|
  #   ast.must_equal [:multi, [:tag, 'Foo', {'bar' => 'baz'}]]
  # end

  parses 'tags with double-quoted attributes', '{Foo bar="baz"}' do |ast|
    ast.must_equal [:multi, [:tag, 'Foo', {'bar' => 'baz'}]]
  end

  # parses 'tags with single-quoted attributes', "{Foo bar='baz'}" do |ast|
  #   ast.must_equal [:multi, [:tag, 'Foo', {'bar' => 'baz'}]]
  # end

  parses 'tags with multiple double-quoted attributes', '{Foo bar="bar" baz="baz"}' do |ast|
    ast.must_equal [:multi, [:tag, 'Foo', {'bar' => 'bar', 'baz' => 'baz'}]]
  end

  parses 'tags attributes with spaces', '{Foo bar="baz boop"}' do |ast|
    ast.must_equal [:multi, [:tag, 'Foo', {'bar' => 'baz boop'}]]
  end

  parses 'asdf', '{Likes limit="4" summarize="150" width="170"}' do |ast|
    ast.must_equal [:multi, [:tag, 'Likes', {'limit' => '4',
                                         'summarize' => '150',
                                             'width' => '170'}]]
  end


  # Blocks

  parses 'block tags', '{block:Description}{/block:Description}' do |ast|
    ast.must_equal [:multi, [:block, 'Description', [:multi]]]
  end

  parses 'blocks with attributes', '{Foo bar="bar" baz="baz"}' do |ast|
    ast.must_equal [:multi, [:tag, 'Foo', {'bar' => 'bar', 'baz' => 'baz'}]]
  end


  # Conditional Blocks

  parses 'if blocks', '{block:IfFoo}Foo{/block:IfFoo}' do |ast|
    ast.must_equal [:multi, [:cond, :if, 'Foo', [:multi,
                              [:static, 'Foo']]]]
  end

  parses 'if not blocks', '{block:IfNotFoo}Foo{/block:IfNotFoo}' do |ast|
    ast.must_equal [:multi, [:cond, :ifnot, 'Foo', [:multi,
                              [:static, 'Foo']]]]
  end


  # Custom Vars

  parses 'color tags', '{color:Content Background}' do |ast|
    ast.must_equal [:multi, [:color, 'Content Background']]
  end

  parses 'font tags', '{font:Lucida Sans}' do |ast|
    ast.must_equal [:multi, [:font, 'Lucida Sans']]
  end

  parses 'lang tags', '{lang:Search results for SearchQuery 2}' do |ast|
    ast.must_equal [:multi, [:lang, 'Search results for SearchQuery 2']]
  end

  parses 'image tags', '{image:Background}' do |ast|
    ast.must_equal [:multi, [:image, 'Background']]
  end


  # Escaping

  %w{Plaintext JS JSPlaintext URLEncoded}.each do |esc|
    parses 'escaped tags', "{#{esc}Foo}" do |ast|
      ast.must_equal [:multi, [:esc, esc.downcase.to_sym, [:tag, 'Foo']]]
    end
  end


  # No-ops

  parses 'all tags to noops', '{Foo Bar Baz}' do |ast|
    ast.must_equal [:multi, [:noop]]
  end


  # Stack Closing

  parses 'unclosed blocks', '{block:Foo}{block:Bar}' do |ast|
    ast.must_equal [:multi, [:block, 'Foo', [:multi,
                              [:block, 'Bar', [:multi]]]]]
  end

  parses 'closes open blocks when switching context', '{block:A}{block:B}{/block:A}' do |ast|
    ast.must_equal [:multi, [:block, 'A', [:multi,
                              [:block, 'B', [:multi]]]]]
  end

  parses 'unintended open tags to close tags', '{block:A}{block:A}' do |ast|
    ast.must_equal [:multi, [:block, 'A', [:multi]]]
  end


  # Block Grouping

  parses 'grouped blocks', '{block:A}Foo{block:B}Bar{/block:A}' do |ast|
    ast.must_equal [:multi, [:block, 'A',
                              [:multi, [:static, 'Foo'],
                                       [:block, 'B',
                                         [:multi, [:static, 'Bar']]]]]]
  end

end
