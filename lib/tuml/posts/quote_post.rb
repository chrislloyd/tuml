class Tuml
  class QuotePost < Post

    # Rendered for Quote posts.
    block 'Quote' do
      true
    end

    # The content of this post.
    tag 'Quote' do
      post['quote-text']
    end

    # Rendered if there is a source for this post.
    block 'Source' do
      not tag('Source').blank?
    end

    # The source for this post (May contain HTML).
    tag 'Source' do
      post['quote-source']
    end

    # The length of the quote.
    tag 'Length' do
      case tag('Quote').length
      when 0...100
        'short'
      when 100...250
        'medium'
      else
        'long'
      end
    end

  end
end
