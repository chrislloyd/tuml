class Tuml
  class VideoPost < Post

    HEIGHT_REGEXP = /height="(\d+)"/

    # Rendered for Video posts.
    block 'Video' do
      true
    end

    # Rendered if there is a caption for this post.
    block 'Caption' do
      find('Caption') != ''
    end

    # The caption for this post.
    tag 'Caption' do
      data['caption']
    end

    [500, 400, 250].each do |width|
      tag "Video-#{width}" do
        data['player'].find {|p| p['width'] == width}['embed_code']
      end
    end

  end
end
