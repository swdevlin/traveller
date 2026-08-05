require 'test_helper'

class LibraryControllerTest < ActionDispatch::IntegrationTest
  setup do
    self.default_url_options = { campaign_slug: campaigns(:one).slug }
  end

  test 'a logged-out request is redirected to sign in' do
    get library_url
    assert_redirected_to new_session_path
  end

  test 'a different campaign\'s referee is redirected, not permitted' do
    sign_in_as users(:two)
    get library_url
    assert_redirected_to new_session_path
  end

  test 'the campaign\'s own referee sees the catalog with current enabled state' do
    sign_in_as users(:one)
    get library_url

    assert_response :success
    assert_includes @response.body, rulebooks(:core).title
  end

  test 'lists only globally searchable, ready rulebooks' do
    sign_in_as users(:one)
    get library_url

    # rulebooks(:hidden) is status: ready but searchable: false — a book the
    # site admin has globally disabled is never a candidate a campaign can enable.
    assert_not_includes @response.body, rulebooks(:hidden).title
    assert_not_includes @response.body, rulebooks(:failed_import).title
    assert_not_includes @response.body, rulebooks(:pending_import).title
  end

  test 'toggle_enabled flips enabled for an existing row' do
    sign_in_as users(:one)
    assert campaign_rulebooks(:core_enabled).enabled?

    patch toggle_enabled_library_url(rulebook_id: rulebooks(:core).id)

    assert_redirected_to library_path
    assert_not campaign_rulebooks(:core_enabled).reload.enabled?
  end

  test 'toggle_enabled creates a row when none exists yet' do
    sign_in_as users(:one)
    rulebook = Rulebook.create!(title: 'Fresh Book', category: 'rulebook', status: 'ready', searchable: true, page_number_offset: 0)

    assert_difference('CampaignRulebook.count') do
      patch toggle_enabled_library_url(rulebook_id: rulebook.id)
    end

    assert CampaignRulebook.find_by(rulebook_id: rulebook.id).enabled?
  end

  test 'disabling a book also clears player_searchable' do
    sign_in_as users(:one)
    campaign_rulebooks(:core_enabled).update!(enabled: true, player_searchable: true)

    patch toggle_enabled_library_url(rulebook_id: rulebooks(:core).id)

    campaign_rulebook = campaign_rulebooks(:core_enabled).reload
    assert_not campaign_rulebook.enabled?
    assert_not campaign_rulebook.player_searchable?
  end

  test 'toggle_player_searchable flips player_searchable for an existing row' do
    sign_in_as users(:one)
    assert campaign_rulebooks(:core_enabled).player_searchable?

    patch toggle_player_searchable_library_url(rulebook_id: rulebooks(:core).id)

    assert_not campaign_rulebooks(:core_enabled).reload.player_searchable?
  end

  test 'marking player_searchable also forces enabled on' do
    sign_in_as users(:one)
    rulebook = Rulebook.create!(title: 'Another Book', category: 'rulebook', status: 'ready', searchable: true, page_number_offset: 0)

    patch toggle_player_searchable_library_url(rulebook_id: rulebook.id)

    campaign_rulebook = CampaignRulebook.find_by(rulebook_id: rulebook.id)
    assert campaign_rulebook.enabled?
    assert campaign_rulebook.player_searchable?
  end

  test 'a non-referee cannot toggle another campaign\'s library' do
    sign_in_as users(:two)
    patch toggle_enabled_library_url(rulebook_id: rulebooks(:core).id)
    assert_redirected_to new_session_path
  end
end
