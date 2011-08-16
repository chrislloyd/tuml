class Tuml
  class ChatPost < Post

    # Rendered for Chat posts.
    block 'Chat' do
      true
    end

    # Rendered if there is a title for this post.
    block 'Title'

    # The title of this post.
    tag 'Title'

    # Rendered for each line of this post.
    block 'Lines'

    class Line < Context

      # Rendered if a label was extracted for the current line of this post.
      block 'Label' do
        true
      end

      # The label (if one was extracted) for the current line of this post.
      tag 'Label' do
        'Foo'
      end

      # The username (if one was extracted) for the current line of this
      # post.
      tag 'Name'

      # The current line of this post.
      tag 'Line'

      # A unique identifying integer representing the user of the current
      # line of this post.
      tag 'UserNumber'

      # "odd" or "even" for each line of this post.
      tag 'Alt'

    end

  end
end
