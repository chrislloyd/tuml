class Tuml
  class PhotoPost < Post

    # Rendered for Photo posts.
    block 'Photo' do
      true
    end

    # The HTML-safe version of the caption (if one exists) of this post.
    tag 'PhotoAlt' do
      data['alt']
    end

    # Rendered if there is a caption for this post.
    block 'Caption' do
      data['caption'] != ''
    end

    # The caption for this post.
    tag 'Caption' do
      data['caption']
    end

    # A click-through URL for this photo if set.
    tag 'LinkURL' do
      data['photo-link-url']
    end

    # An HTML open anchor-tag including the click-through URL if set.
    tag 'LinkOpenTag' do
      "<a" + if url = find('LinkURL')
        " href='#{url}'>"
      else
        '>'
      end
    end

    # A closing anchor-tag output only if a click-through URL is set.
    tag 'LinkCloseTag' do
      '</a>'
    end


    # URL for the photo of this post.
    [500, 400, 250, 100].each do |n|
      tag "PhotoUrl-#{n}" do
        data['photos'].
          first['alt_sizes'].
          find(->{{}}) {|p| p['width'] == n}['url']
      end
    end

    tag "PhotoUrl-75sq" do
      data['photos'].
        first['alt_sizes'].
        find(->{{}}) {|p| p['width'] == 75}['url']
    end

    # Rendered if there is a high-res photo for this post.
    block 'HighRes' do
      data['photos'].first['alt_sizes'].exist? {|p| p['width'] == 1280}
    end

    # URL for the high-res photo of this post. Rendered if there is high-res
    # photo for this post.
    tag 'PhotoURL-HighRes' do
      data['photos'].
        first['alt_sizes'].
        find(->{{}}) {|p| p['width'] == 1280}['url']
    end

    # Embed-code for the photoset.
    [500, 400, 250].each do |n|
      # tag "Photoset-#{n}"
    end

  end
end
