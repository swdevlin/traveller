# frozen_string_literal: true

require 'test_helper'

# GET /star_systems/:id and GET /parsecs/lookup are cached against the system's updated_at:
# a caller with a current copy gets a 304, and the rendered JSON is kept in Rails.cache.
class Api::StarSystemDetailCachingTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
    @sector = Sector.create!(name: 'Caching Sector', x: 92, y: 92, abbreviation: 'Cch')
    parsec = Parsec.create!(sector: @sector, x: 92 * 32, y: 92 * 40)
    @system = StarSystem.create!(name: 'Caching System', parsec: parsec, known: true)
    @star = Star.create!(star_system: @system, colour: 'Yellow', stellar_type: 'G', stellar_subtype: 2, luminosity: 'V',
                         diameter: 1_392_000, jump_shadow: 139_200_000)
    @planet = TerrestrialPlanet.create!(
      size_code: '5', atmosphere_code: 6, hydrographics_code: 5, population_code: 6, government_code: 5,
      law_level_code: 5, tech_level_code: 8, starport_code: 'A', orbiting: @star, orbit: 1.0, au: 1.0, diameter: 12_742,
      name: 'Original Name'
    )
    @urls = {
      'star system' => "/c/#{@campaign.slug}/api/star_systems/#{@system.id}",
      'parsec lookup' => "/c/#{@campaign.slug}/api/parsecs/lookup?sx=92&sy=92&hx=1&hy=1"
    }
    @cache = ActiveSupport::Cache::MemoryStore.new
  end

  # The block runs with a real cache, as the test environment's is a null store.
  def with_cache
    original = Rails.cache
    Rails.cache = @cache
    yield
  ensure
    Rails.cache = original
  end

  def etag = response.headers['ETag']

  def planet_name_in_body
    detail = response.parsed_body['star_system'] || response.parsed_body
    detail['primary_star']['stellar_objects'].detect { |object| object['id'] == @planet.id }['name']
  end

  def stellar_object_queries
    queries = []
    counter = ->(*, payload) { queries << payload[:sql] if payload[:sql].include?('FROM "stellar_objects"') }
    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') { yield }
    queries.size
  end

  test 'the response carries an ETag and may only be cached privately' do
    @urls.each do |name, url|
      get url, as: :json

      assert_response :success, name
      assert etag.present?, "#{name}: no ETag"
      assert_includes response.headers['Cache-Control'], 'private', name
    end
  end

  test 'a caller with a current copy gets 304 and no body' do
    @urls.each do |name, url|
      get url, as: :json
      get url, headers: { 'If-None-Match' => etag }, as: :json

      assert_response :not_modified, name
      assert response.body.blank?, name
    end
  end

  test 'a 304 does not load the system' do
    get @urls['star system'], as: :json
    current = etag

    assert_equal 0, stellar_object_queries { get @urls['star system'], headers: { 'If-None-Match' => current }, as: :json }
    assert_response :not_modified
  end

  test 'editing a body gives a new ETag and the new content' do
    @urls.each do |name, url|
      get url, as: :json
      before = etag
      assert_equal 'Original Name', planet_name_in_body, name

      @planet.update!(name: 'Edited Name')
      get url, headers: { 'If-None-Match' => before }, as: :json

      assert_response :success, name
      assert_not_equal before, etag, name
      assert_equal 'Edited Name', planet_name_in_body, name
      @planet.update!(name: 'Original Name')
    end
  end

  test 'the referee and a player have different ETags' do
    get @urls['star system'], as: :json
    player = etag

    sign_in_as users(:one)
    get @urls['star system'], as: :json

    assert_not_equal player, etag
  end

  test 'a stale ETag from before signing in does not give the referee a 304' do
    get @urls['star system'], as: :json
    player = etag

    sign_in_as users(:one)
    get @urls['star system'], headers: { 'If-None-Match' => player }, as: :json

    assert_response :success
  end

  test 'the parsec lookup ETag changes when only the parsec changes' do
    get @urls['parsec lookup'], as: :json
    before = etag

    @system.parsec.update!(survey_index: 7)
    get @urls['parsec lookup'], as: :json

    assert_not_equal before, etag
    assert_equal 7, response.parsed_body['survey_index']
  end

  test 'the rendered JSON is kept, so a second caller does not load the system' do
    with_cache do
      @urls.each do |name, url|
        get url, as: :json
        first_body = response.body
        assert_operator stellar_object_queries { get url, as: :json }, :==, 0, "#{name}: the system was loaded again"

        assert_equal first_body, response.body, name
      end
    end
  end

  test 'a cached copy is not served after an edit' do
    with_cache do
      @urls.each do |name, url|
        get url, as: :json
        @planet.update!(name: 'Edited Name')
        get url, as: :json

        assert_equal 'Edited Name', planet_name_in_body, name
        @planet.update!(name: 'Original Name')
      end
    end
  end

  test 'what the referee sees is never served to a player from the cache' do
    @planet.update!(tag_names: ['secret-tag'])

    with_cache do
      sign_in_as users(:one)
      get @urls['star system'], as: :json
      assert_includes response.body, 'secret-tag'

      sign_out
      get @urls['star system'], as: :json
      assert_not_includes response.body, 'secret-tag'
    end
  end

  # Sophont referee notes are shown to the signed-in owner only, not to a token caller, so the
  # two must not share a cached copy whichever of them fills it.
  test 'the owner and a token caller each get their own cached copy' do
    sophont = Sophont.create!(name: 'Zhodani Test', referee_notes: 'owner-only notes')
    @planet.update!(native_sophont: true, sophont_id: sophont.id)
    token = { 'Authorization' => "Bearer #{@campaign.api_token}" }

    [%i[token owner], %i[owner token]].each do |order|
      @cache.clear
      sign_out
      order.each do |who|
        with_cache do
          if who == :owner
            sign_in_as users(:one)
            get @urls['star system'], as: :json
            assert_includes response.body, 'owner-only notes', "owner, after #{order.first} filled the cache"
          else
            sign_out
            get @urls['star system'], headers: token, as: :json
            assert_not_includes response.body, 'owner-only notes', "token, after #{order.first} filled the cache"
          end
        end
      end
    end
  end

  test 'a tag change reaches the referee, who sees it after the next request' do
    sign_in_as users(:one)
    with_cache do
      get @urls['star system'], as: :json
      assert_not_includes response.body, 'later-tag'

      @planet.update!(tag_names: ['later-tag'])
      get @urls['star system'], as: :json
      assert_includes response.body, 'later-tag'

      @planet.tag_names = []
      get @urls['star system'], as: :json
      assert_not_includes response.body, 'later-tag'
    end
  end

  test 'an unknown system is still not found' do
    get "/c/#{@campaign.slug}/api/star_systems/0", as: :json

    assert_response :not_found
  end

  test 'an empty hex is answered without a cached system' do
    get "/c/#{@campaign.slug}/api/parsecs/lookup?sx=92&sy=92&hx=2&hy=2", as: :json
    assert_response :not_found
  end
end
