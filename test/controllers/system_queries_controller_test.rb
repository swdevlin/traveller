require 'test_helper'

class SystemQueriesControllerTest < AuthenticatedIntegrationTest
  setup do
    @system_query = SystemQuery.create!(name: 'Tech worlds', rule_data: {}, columns: %w[uwp])
    @star_system = StarSystem.create!(name: 'Test System', parsec: parsecs(:one))
  end

  test 'should get index' do
    get system_queries_url
    assert_response :success
  end

  test 'the query form offers a tags display column' do
    get new_system_query_url
    assert_select 'input[type=checkbox][value=tags]'
  end

  test 'show renders a tags column when chosen' do
    @star_system.update!(tag_list: 'Column tag')
    @system_query.update!(columns: %w[tags])
    get system_query_url(@system_query)
    assert_select 'th', text: 'Tags'
    assert_select 'td [aria-label=Tags] a', text: 'Column tag'
  end

  test 'show matches a system whose body carries the tag' do
    body = StellarObject.where(star_system_id: @star_system.id).first || StellarObject.where.not(star_system_id: nil).first!
    system = StarSystem.find(body.star_system_id)
    body.update!(tag_list: 'Body tag')
    @system_query.update!(rule_data: {
      groups: [[{ field: 'tags', operator: 'has', values: ['Body tag'], negate: false }]]
    })
    get system_query_url(@system_query)
    assert_response :success
    assert_includes @response.body, system.name
  end

  test 'should get new' do
    get new_system_query_url
    assert_response :success
  end

  test 'should create system query' do
    assert_difference('SystemQuery.count') do
      post system_queries_url, params: { system_query: { name: 'New Query', columns: %w[uwp] } }
    end

    assert_redirected_to system_query_url(SystemQuery.last)
  end

  test 'should reject creating a system query with invalid rule data json' do
    assert_no_difference('SystemQuery.count') do
      post system_queries_url, params: { system_query: { name: 'New Query', rule_data_json: 'not json' } }
    end

    assert_response :unprocessable_entity
  end

  test 'should show system query results, paginated' do
    get system_query_url(@system_query)

    assert_response :success
    assert_includes @response.body, @star_system.name
  end

  test 'show returns tagged systems but not neighbours that only share an enclosing area tag' do
    @star_system.update!(tag_list: 'A Thd Tag')
    @star_system.parsec.subsector.update!(tag_list: 'A Thd Tag')
    @star_system.parsec.sector.update!(tag_list: 'A Thd Tag')
    regions(:one).update!(tag_list: 'A Thd Tag')
    untagged_system = StarSystem.create!(name: 'Untagged neighbour', parsec: @star_system.parsec)
    @system_query.update!(rule_data: {
      groups: [[{ field: 'tags', operator: 'has', values: ['A Thd Tag'], negate: false }]]
    })

    get system_query_url(@system_query)
    assert_response :success
    assert_select 'tbody', text: /#{Regexp.escape(@star_system.name)}/
    assert_select 'tbody', text: /#{Regexp.escape(untagged_system.name)}/, count: 0

    @star_system.update!(tag_list: '')
    get system_query_url(@system_query)
    assert_response :success
    assert_select 'tbody', text: /#{Regexp.escape(@star_system.name)}/, count: 0
  end

  test 'show always renders the combined sector/location column and name first, even when not chosen' do
    @system_query.update!(columns: [])

    get system_query_url(@system_query)

    assert_response :success
    header_order = @response.body.scan(%r{<th scope='col'[^>]*>([^<]*)</th>}).flatten.map(&:strip)
    assert_equal %w[Location Name], header_order.first(2)
  end

  test 'show renders sector and hex code combined in the location column' do
    get system_query_url(@system_query)

    assert_response :success
    assert_includes @response.body, "#{@star_system.parsec.sector.name} #{@star_system.parsec.hex_code}"
  end

  test 'filter criteria links jump_route, allegiance, sector and subsector values to their show pages' do
    route = JumpRoute.create!(name: 'Spinward Main')
    @system_query.update!(
      rule_data: {
        groups: [[
          { field: 'jump_route', operator: 'eq', negate: false, values: [route.id.to_s] },
          { field: 'allegiance', operator: 'eq', negate: false, values: [allegiances(:one).code] },
          { field: 'sector', operator: 'eq', negate: false, values: [sectors(:one).id.to_s] },
          { field: 'subsector', operator: 'eq', negate: false, values: [subsectors(:subsector_1_1).id.to_s] }
        ]]
      }
    )

    get system_query_url(@system_query)

    assert_response :success
    assert_includes @response.body, "href=\"#{jump_route_path(route)}\""
    assert_includes @response.body, "href=\"#{allegiance_path(allegiances(:one))}\""
    assert_includes @response.body, "href=\"#{sector_path(sectors(:one))}\""
    assert_includes @response.body, "href=\"#{subsector_path(subsectors(:subsector_1_1))}\""
  end

  test 'tag filter badges link to the tag show page outside the query frame' do
    @star_system.update!(tag_list: 'Research, Frontier')
    @system_query.update!(rule_data: {
      groups: [[{ field: 'tags', operator: 'has_one_of', values: ['Research', 'Frontier'] }]]
    })
    [system_queries_url, system_query_url(@system_query)].each do |url|
      get url
      assert_response :success
      ['Research', 'Frontier'].each do |name|
        assert_select '[aria-label="Filter criteria"] a[data-turbo-frame="_top"][href=?]', tag_path(name: name), text: name
      end
    end
    get tag_url(name: 'Research')
    assert_response :success
    assert_select '.page-title', text: 'Research'
  end

  test 'filter criteria falls back to plain text for a jump_route id that no longer exists' do
    route = JumpRoute.create!(name: 'Temp Route')
    @system_query.update!(
      rule_data: { groups: [[{ field: 'jump_route', operator: 'eq', negate: false, values: [route.id.to_s] }]] }
    )
    route_id = route.id
    route.destroy!

    get system_query_url(@system_query)

    assert_response :success
    assert_includes @response.body, route_id.to_s
    assert_not_includes @response.body, "href=\"#{jump_route_path(route_id)}\""
  end

  test 'should get edit' do
    get edit_system_query_url(@system_query)
    assert_response :success
  end

  test 'should update system query' do
    patch system_query_url(@system_query), params: { system_query: { name: 'Renamed', columns: @system_query.columns } }

    assert_redirected_to system_query_url(@system_query)
    assert_equal 'Renamed', @system_query.reload.name
  end

  test 'patching only name leaves existing rule data untouched' do
    @system_query.update!(
      rule_data: { groups: [[{ field: 'starport', operator: 'eq', negate: false, values: ['A'] }]] }
    )

    patch system_query_url(@system_query), params: { system_query: { name: 'Renamed', columns: @system_query.columns } }

    assert_redirected_to system_query_url(@system_query)
    @system_query.reload
    assert_equal 'Renamed', @system_query.name
    assert_equal 1, @system_query.groups.size
  end

  test 'should destroy system query' do
    assert_difference('SystemQuery.count', -1) do
      delete system_query_url(@system_query)
    end

    assert_redirected_to system_queries_url
  end
end
