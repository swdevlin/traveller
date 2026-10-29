require 'test_helper'

class RegionsControllerTest < AuthenticatedIntegrationTest
  setup do
    @region = regions(:one)
  end

  test 'region tags can be edited, linked and cleared' do
    patch region_url(@region), params: { region: { tag_list: ' Research, Frontier, Research ' } }
    assert_redirected_to region_url(@region)
    assert_equal ['Frontier', 'Research'], @region.reload.tag_names
    get edit_region_url(@region)
    assert_response :success
    assert_select 'input[name="region[tag_list]"][value="Frontier, Research"]'
    get region_url(@region)
    assert_select '[aria-label=Tags] a[href=?]', tag_path(name: 'Research'), text: 'Research'
    patch region_url(@region), params: { region: { tag_list: '' } }
    assert_equal [], @region.reload.tag_names
  end

  test 'should get index' do
    get regions_url
    assert_response :success
  end

  test 'should get new' do
    get new_region_url
    assert_response :success
  end

  test 'should create region' do
    assert_difference('Region.count') do
      post regions_url, params: { region: { name: 'New Region', label: 'NR', source: 'manual', player_notes: '' } }
    end

    assert_redirected_to region_url(Region.last)
  end

  test 'should show region' do
    get region_url(@region)
    assert_response :success
  end

  test 'should get edit' do
    get edit_region_url(@region)
    assert_response :success
  end

  test 'should update region' do
    patch region_url(@region), params: { region: { name: @region.name, label: @region.label, player_notes: @region.player_notes } }
    assert_redirected_to region_url(@region)
  end

  test 'should toggle player visible' do
    assert_not @region.player_visible?

    patch region_url(@region), params: { region: { player_visible: true } }

    assert_redirected_to region_url(@region)
    assert @region.reload.player_visible?
  end

  test 'should destroy region' do
    assert_difference('Region.count', -1) do
      delete region_url(@region)
    end

    assert_redirected_to regions_url
  end
end
