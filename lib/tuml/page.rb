require 'uri'

class Tuml
  class Page < Context

    RSS_PATH = '/rss'
    DUMMY_CUSTOM_CSS = "#rollrdummy {};"

  AVATAR_SIZES = [16, 24, 30, 40, 48, 64, 96, 128, 512]

    ## Basic Variables

    # The HTML-safe title of your blog.
    tag 'Title' do
      sanitize data['title']
    end

    # The description of your blog. (may include HTML)
    tag 'Description' do
      data['description']
    end

    # The HTML-safe description of your blog. (use in META tag)
    tag 'MetaDescription' do
      sanitize find('description')
    end

    # RSS feed URL for your blog.
    tag 'RSS' do
      absolute_url RSS_PATH
    end

    # Favicon URL for your blog. Just the smallest portrait.
    tag 'Favicon' do
      find('PortraitURL-16')
    end

    # Any custom CSS code added on your 'Customize Theme' screen.
    tag 'CustomCSS' do
      DUMMY_CUSTOM_CSS
    end



    # Portrait photo URL for your blog.
    AVATAR_SIZES.each do |size|
      tag "PortraitURL-#{size}" do
        "http://api.tumblr.com/v2/chrislloyd.com.au/avatar/#{size}"
      end
    end


    ## Followers/Following

    # Rendered if you're following other blogs.
    block 'Following' do
      raw_block('Following').each {|elm| Follower.new(elm)}
    end

    # Rendered for each blog you're following.
    block 'Followed' do
      raw_block('Followed').each {|elm| Follower.new(elm)}
    end

    class Follower < Context
      # The username of the blog you're following.
      tag 'FollowedName'

      # The title of the blog you're following.
      tag 'FollowedTitle'

      # The URL for the blog you're following.
      tag 'FollowedURL'

      # Portrait photo URL for the blog you're following.
      AVATAR_SIZES.each do |n|
        tag "FollowedPortraitURL-#{n}"
      end
    end


    ## Group Blogs

    # Rendered on additional public group blogs.
    block 'GroupMembers' do
      raw_block('GroupMembers').empty?
    end

    # Rendered for each additional public group blog member.
    block 'GroupMember' do
      raw_block('GroupMembers').map {|member| GroupMember.new(member)}
    end

    class GroupMember < Context
      # The username of the member's blog.
      tag 'GroupMemberName'

      # The title of the member's blog.
      tag 'GroupMemberTitle'

      # The URL for the member's blog.
      tag 'GroupMemberURL'

      # Portrait photo URL for the member.
      AVATAR_SIZES.each do |n|
        tag "GroupMemberPortraitURL-#{n}"
      end
    end


    ## Likes

    # Rendered if you are sharing your likes.
    block 'Likes' do
      false
    end

    # Standard HTML output of your likes.
    # Standard HTML output of your last 5 likes. Maximum: 10
    # Standard HTML output of your likes with Audio and Video players scaled
    #   to 200-pixels wide. (Scale images with CSS max-width or similar.)
    # Standard HTML output of your likes with text summarize to
    #   100-characters. Maximum: 250
    tag 'Likes' #, :limit => 5, :width => 200, :summarize => 100


    ## Navigation

    # Rendered if there is a 'previous' or 'next' page.
    block 'Pagination' do
      false
    end

    # Rendered if there is a 'previous' page (newer posts) to navigate to.
    block 'PreviousPage' do
      page_number > 1
    end

    # Rendered if there is a 'next' page (older posts) to navigate to.
    block 'NextPage'
    # page < (20 - 6)


    # URL for the 'previous' page (newer posts).
    tag 'PreviousPage'

    # URL for the 'next' page (older posts).
    tag 'NextPage'

    # Current page number.
    tag 'CurrentPage'

    # Total page count.
    tag 'TotalPages'

    # TODO
    # Rendered if Submissions are enabled.
    block 'SubmissionsEnabled' do
      false
    end

    # The customizable label for the Submit link. (Example: 'Submit')
    tag 'SubmitLabel' do
      'Submit'
    end

    # Rendered if asking questions is enabled.
    block 'AskEnabled' do
      data['ask'] && []
    end

    # The customizable label for the Ask link. (Example: 'Ask me anything')
    tag 'AskLabel' do
      'Ask me anything'
    end


    ## Custom Pages

    class CustomPage < Context
      # The URL for this page.
      tag 'URL' do
        data['url']
      end

      # The label for this page.
      tag 'Label' do
        data['label']
      end
    end

    # Rendered if you have defined any custom pages.
    block 'HasPages' do
      not raw_block('Pages').empty?
    end

    # Rendered for each custom page.
    block 'Pages' do
      # data['pages'].map {|page| CustomPage.new prototype: self, data: page}
      []
    end


    ## Twitter

    # Rendered if you have Twitter integration enabled.
    tag 'Twitter'

    # Your Twitter username.
    tag 'TwitterUsername' do
      data('twitter_username') || 'chrislloyd'
    end


    # Undocumented
    block 'NoSearchResults' do
      true
    end


  private

    # TODO
    def sanitize text, opts={}
      # Sanitize.clean text, opts
      text
    end

    def absolute_url *path_segments
      path_segments.join
      # URI.join(host, *path_segments).to_s
    end

    def local_url url
      URI.parse(url).path
    end

  end
end
