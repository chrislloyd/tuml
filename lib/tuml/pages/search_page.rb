class SearchPage < Page

  # The URL for this page.
  tag 'URL'

  # The label for this page.
  tag 'Label'

  # This block gets rendered for each post in reverse chronological order.
  # The number of posts that appear per-page can be configured the the
  # Customize area for the blog on the Advanced tab.
  block 'Posts'
  # do
  #   data['posts'].
  #     map {|p| Post.for post}.
  #     filter {|p| p.contains? search_query}
  # end

  # Rendered on search pages.
  block 'SearchPage' do
    true
  end

  # The current search query.
  tag 'SearchQuery' do
    search_query
  end

  # A URL-safe version of the current search query for use in links and
  # Javascript.
  tag 'URLSafeSearchQuery' do
    CGI.escape search_query
  end

  # The number of results returned for the current search query.
  tag 'SearchResultCount' do
    posts.length
  end

  # Rendered if no search results were returned for the current search
  # query.
  tag 'NoSearchResults' do
    search_result_count.zero?
  end

end
