class TagPage < Page

  # The URL for this page.
  tag 'URL'

  # The label for this page.
  tag 'Label'

  block 'Posts'

  # Rendered on tag pages.
  block 'TagPage'

  # The name of this tag.
  tag 'Tag'

  # A URL safe version of this tag.
  tag 'URLSafeTag'

  # The tag page URL with other posts that share this tag.
  tag 'TagURL'

  # The tag page URL with other posts that share this tag in chronological
  # order.
  tag 'TagURLChrono'

end
