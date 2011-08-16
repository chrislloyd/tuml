class Tuml
  class AnswerPost < Post

    # Rendered for Answer posts.
    block 'Answer' do
      true
    end

    # The question for this post. (May contain heavily filtered HTML).
    tag 'Question' do
      data['question']
    end

    # The answer for this post. (May contain HTML)
    tag 'Answer' do
      data['answer']
    end

    # Simple HTML text link with the asker's username and URL, or the plain
    # text string "Anonymous".
    tag 'Asker' do
      "<a href='#{data['AskingURL']}'>#{data['AskingName']}</a>"
    end

    # Portrait photo URL for the asker.
    AVATAR_SIZES.each do |size|
      tag "AskerPortraitURL-#{size}" do
        # TODO
      end
    end

  end
end
