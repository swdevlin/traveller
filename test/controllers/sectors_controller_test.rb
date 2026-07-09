require 'test_helper'

class SectorsControllerTest < AuthenticatedIntegrationTest
  setup do
    @sector = sectors(:one)
  end

  test 'should get index' do
    get sectors_url
    assert_response :success
  end

  test 'should get new' do
    get new_sector_url
    assert_response :success
  end

  test 'should create sector' do
    assert_difference('Sector.count') do
      post sectors_url, params: { sector: { abbreviation: @sector.abbreviation, name: @sector.name, x: 12, y: 12 } }
    end

    assert_redirected_to sector_url(Sector.last)
  end

  test 'should show sector' do
    get sector_url(@sector)
    assert_response :success
  end

  test 'should get edit' do
    get edit_sector_url(@sector)
    assert_response :success
  end

  test 'should update sector' do
    patch sector_url(@sector), params: { sector: { abbreviation: @sector.abbreviation, name: @sector.name, x: @sector.x, y: @sector.y } }
    assert_redirected_to sector_url(@sector)
  end

  test 'should destroy sector' do
    assert_difference('Sector.kept.count', -1) do
      delete sector_url(@sector)
    end

    assert_redirected_to sectors_url
  end

  test 'import_jump_routes creates jump routes and links on success' do
    stub_request(:get, 'https://travellermap.com/api/metadata?sx=1&sy=-1')
      .to_return(status: 200, body: {
        'Routes' => [{ 'Start' => '0101', 'End' => '0202', 'EndOffsetY' => -1 }]
      }.to_json)

    assert_difference ['JumpRoute.count', 'JumpRouteLink.count'], 1 do
      post import_jump_routes_sector_url(@sector)
    end

    assert_redirected_to sector_url(@sector)
    assert_match(/1 new link/, flash[:notice])
    assert JumpRoute.find_by(travellermap_allegiance_code: 'Im')
  end

  test 'import_jump_routes shows an alert and creates nothing when the fetch fails' do
    stub_request(:get, 'https://travellermap.com/api/metadata?sx=1&sy=-1').to_return(status: 500, body: 'boom')

    assert_no_difference ['JumpRoute.count', 'JumpRouteLink.count'] do
      post import_jump_routes_sector_url(@sector)
    end

    assert_redirected_to sector_url(@sector)
    assert flash[:alert].present?
  end
end
