class DayPage < TemplateContext

  # The URL for this page.
  tag 'URL'

  # The label for this page.
  tag 'Label'

  block 'Posts'

  # Rendered on day pages.
  block 'DayPage'

  # Rendered if there is a 'previous' or 'next' day page.
  block 'DayPagination'

  # Rendered if there is a 'previous' day page to navigate to.
  block 'PreviousDayPage'

  # URL for the 'previous' day page.
  tag 'PreviousDayPage'

  # Rendered if there is a 'next' day page to navigate to.
  block 'NextDayPage'

  # URL for the 'next' day page.
  tag 'NextDayPage'

end
