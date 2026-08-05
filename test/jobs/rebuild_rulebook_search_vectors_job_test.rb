require 'test_helper'

class RebuildRulebookSearchVectorsJobTest < ActiveJob::TestCase
  test 'renormalizes every page for the given rulebook' do
    rulebook = rulebooks(:core)
    rulebook.update!(header_footer_patterns: ['CORE RULEBOOK'])

    RebuildRulebookSearchVectorsJob.perform_now(rulebook.id)

    page = rulebook_pages(:core_page_starships).reload
    assert_not_includes page.normalized_body, 'CORE RULEBOOK'
  end

  test 'logs and does not raise when the rulebook cannot be found' do
    assert_nothing_raised do
      RebuildRulebookSearchVectorsJob.perform_now(-1)
    end
  end
end
