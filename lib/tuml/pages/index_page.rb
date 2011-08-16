class Tuml
  class IndexPage < Page

    # TODO Options
    POSTS_PER_PAGE = 10

    attr_accessor :page_number

    def initialize args={}
      super
      self.page_number = args[:page_number] || 1
    end

    block 'IndexPage' do
      true
    end

    # TODO: Pagination
    block 'Posts' do
      # start_index = (POSTS_PER_PAGE * page) - 1
      # end_index = [start_index + POSTS_PER_PAGE, data['posts'].length].min
      data['posts'].map do |post|

        Post.for(post)
      end
    end

    ## Jump Pagination

    class JumpPagination < Context
      # Rendered when jump page is the current page.
      block 'CurrentPage'

      # Rendered when jump page is not the current page.
      block 'JumpPage'

      # Page number for jump page.
      tag 'PageNumer'

      # URL for jump page.
      tag 'URL'
    end

    # Rendered for each page greater than the current page minus one-half
    # length up to current page plus one-half length.
    block 'JumpPagination' do |length=5|

    end

  end
end