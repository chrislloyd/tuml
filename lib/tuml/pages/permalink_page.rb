class PermalinkPage < Page
  attr_accessor :post_id

  def initialize prototype, post_id
    super prototype
    self.post_id = post_id
  end

  # The URL for this page.
  tag 'URL'

  # The label for this page.
  tag 'Label'

  # Rendered on post permalink pages. (Useful for embedding comment
  # widgets)
  block 'PermalinkPage' do
    true
  end

  # Rendered on permalink pages. (Useful for displaying the current post's
  # title in the page title)
  block 'PostTitle'

  tag 'PostTitle'

  # Identical to {PostTitle}, but will automatically generate a summary if
  # a title doesn't exist.
  block 'PostSummary' do
    false
  end

  tag 'PostSummary'

  block 'Posts' do
    data['posts'].
      select {|post| post['id'] == post_id}.
      map {|post| Post.for self, post}
  end

end
