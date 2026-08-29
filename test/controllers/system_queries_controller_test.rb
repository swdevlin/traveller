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
