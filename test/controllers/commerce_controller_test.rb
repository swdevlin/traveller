# frozen_string_literal: true

require 'test_helper'

class CommerceControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
    self.default_url_options = { campaign_slug: @campaign.slug }
    @sector = Sector.create!(name: 'Commerce Controller Test Sector', x: 99, y: 99, abbreviation: 'Cmc')
  end

  def build_star_system(x, y, **attrs)
    parsec = Parsec.create!(sector: @sector, x: x, y: y, q: x, r: y, s: -x - y)
    StarSystem.create!({ name: "System #{x},#{y}", parsec: parsec }.merge(attrs))
  end

  test 'show redirects to login when not authenticated' do
    get commerce_url
    assert_response :redirect
  end

  test 'show succeeds for the referee with no systems selected' do
    sign_in_as users(:one)

    get commerce_url
    assert_response :success
  end

  test 'show computes passage, freight and mail traffic once both systems are selected' do
    sign_in_as users(:one)
    from = build_star_system(0, 0)
    to   = build_star_system(4, 0)

    get commerce_url(from_id: from.id, to_id: to.id)

    assert_response :success
  end

  test 'show computes mail traffic using the mail-specific inputs' do
    sign_in_as users(:one)
    from = build_star_system(0, 0)
    to   = build_star_system(4, 0)

    get commerce_url(from_id: from.id, to_id: to.id, tab: 'mail',
                      mail_ship_armed: '1', mail_naval_or_scout_rank: 2, mail_soc_dm: 1, mail_referee_modifier: -1)

    assert_response :success
  end

  test 'show shows an alert and does not compute when origin and destination are the same' do
    sign_in_as users(:one)
    system = build_star_system(10, 0)

    get commerce_url(from_id: system.id, to_id: system.id)

    assert_response :success
    assert_equal 'Origin and destination must be different systems.', flash[:alert]
  end

  test 'show computes a trade goods availability list once both systems are selected' do
    sign_in_as users(:one)
    from = build_star_system(0, 0)
    to   = build_star_system(4, 0)

    get commerce_url(from_id: from.id, to_id: to.id, tab: 'trade')

    assert_response :success
    assert_select 'table'
  end

  test 'the trade seed persists across two GETs, keeping the goods list stable' do
    sign_in_as users(:one)
    from = build_star_system(0, 0)
    to   = build_star_system(4, 0)

    get commerce_url(from_id: from.id, to_id: to.id, tab: 'trade')
    first_seed = css_select('input[name="trade_seed"]').first['value']

    get commerce_url(from_id: from.id, to_id: to.id, tab: 'trade', trade_seed: first_seed)
    second_seed = css_select('input[name="trade_seed"]').first['value']

    assert_equal first_seed, second_seed
  end

  test 'trade_resurvey mints a new seed' do
    sign_in_as users(:one)
    from = build_star_system(0, 0)
    to   = build_star_system(4, 0)

    get commerce_url(from_id: from.id, to_id: to.id, tab: 'trade')
    first_seed = css_select('input[name="trade_seed"]').first['value']

    get commerce_url(from_id: from.id, to_id: to.id, tab: 'trade', trade_seed: first_seed, trade_resurvey: '1')
    second_seed = css_select('input[name="trade_seed"]').first['value']

    refute_equal first_seed, second_seed
  end

  test 'rolling purchase prices renders a price for every good in the goods table' do
    sign_in_as users(:one)
    from = build_star_system(0, 0)
    to   = build_star_system(4, 0)

    get commerce_url(from_id: from.id, to_id: to.id, tab: 'trade')
    seed = css_select('input[name="trade_seed"]').first['value']

    get commerce_url(from_id: from.id, to_id: to.id, tab: 'trade', trade_seed: seed, trade_purchase_submit: '1')

    assert_response :success
    assert_select 'th', text: 'Purchase Price'
  end

  test 'rolling sale prices renders a full price table for every priceable good' do
    sign_in_as users(:one)
    from = build_star_system(0, 0)
    to   = build_star_system(4, 0)

    get commerce_url(from_id: from.id, to_id: to.id, tab: 'trade')
    seed = css_select('input[name="trade_seed"]').first['value']

    get commerce_url(from_id: from.id, to_id: to.id, tab: 'trade', trade_seed: seed, trade_sale_submit: '1')

    assert_response :success
    assert_select 'th', text: 'Sale Price'
    assert_select 'table', count: 2
  end

  test 'rolling sale prices with a local broker applies the fee to the shown price' do
    sign_in_as users(:one)
    from = build_star_system(0, 0)
    to   = build_star_system(4, 0)

    get commerce_url(from_id: from.id, to_id: to.id, tab: 'trade')
    seed = css_select('input[name="trade_seed"]').first['value']

    get commerce_url(from_id: from.id, to_id: to.id, tab: 'trade', trade_seed: seed, trade_sale_submit: '1',
                      trade_sale_use_broker: '1', trade_sale_broker_level: '3', trade_sale_broker_fee_percentage: '10')

    assert_response :success
    assert_select 'th', text: 'Sale Price'
    assert_select '.text-fg-muted', text: /Broker fee 10%/
  end

  test 'trade broker checkbox and level default from the campaign settings' do
    @campaign.local_broker_level = 3
    @campaign.local_broker_fee_percentage = 15
    @campaign.save!
    sign_in_as users(:one)
    from = build_star_system(0, 0)
    to   = build_star_system(4, 0)

    get commerce_url(from_id: from.id, to_id: to.id, tab: 'trade')

    assert_response :success
    assert_select 'input[name="trade_purchase_broker_level"][value="3"]'
    assert_select 'input[name="trade_purchase_broker_fee_percentage"][value="15"]'
  end
end
