require 'test_helper'

class ObjectTagsControllerTest < AuthenticatedIntegrationTest
  setup do
    @records = [sectors(:one), subsectors(:subsector_1_1), star_systems(:in_one),
                gas_giants(:small), stars(:star_one), regions(:one)]
    @records.each { |record| record.update!(tag_list: 'Research, Frontier') }
  end

  def tag_params(record, **extra)
    { record_type: record.class.base_class.name, record_id: record.id, **extra }
  end

  test 'add tags in place for every supported object type without replacing existing tags' do
    @records.each do |record|
      post object_tags_url, params: tag_params(record, tag_list: ' Research, New tag, '),
           headers: { 'Turbo-Frame' => ActionView::RecordIdentifier.dom_id(record, :tags) }
      assert_response :success
      assert_equal ['Frontier', 'New tag', 'Research'], record.reload.tag_names
      assert_select 'turbo-frame[id=?]', ActionView::RecordIdentifier.dom_id(record, :tags)
      assert_select 'a[data-turbo-frame="_top"][href=?]', tag_path(name: 'New tag'), text: 'New tag'
    end
  end

  test 'remove a tag from the selected object without deleting it elsewhere' do
    @records.each do |record|
      delete object_tags_url, params: tag_params(record, tag: 'Research'),
             headers: { 'Turbo-Frame' => ActionView::RecordIdentifier.dom_id(record, :tags) }
      assert_response :success
      assert_equal ['Frontier'], record.reload.tag_names
      assert_select '[aria-label="Remove Research"]', count: 0
    end
    assert_includes Tag.names, 'Frontier'
  end

  test 'empty input shows an inline error without changing tags' do
    record = sectors(:one)
    post object_tags_url, params: tag_params(record, tag_list: ' , '),
         headers: { 'Turbo-Frame' => ActionView::RecordIdentifier.dom_id(record, :tags) }
    assert_response :unprocessable_entity
    assert_select '[role=alert]', text: 'Enter a tag to add.'
    assert_equal ['Frontier', 'Research'], record.reload.tag_names
  end

  test 'empty tag sections still offer an inline editor' do
    record = regions(:one)
    record.update!(tag_list: '')
    get region_url(record)
    assert_response :success
    assert_select '.page-side form[action=?] input[name=tag_list]', object_tags_path
  end

  test 'non-frame submissions return to the object detail page' do
    record = stars(:star_one)
    post object_tags_url, params: tag_params(record, tag_list: 'New tag')
    assert_redirected_to star_url(record)
  end

  test 'tag removal affects only the requested assignment' do
    delete object_tags_url, params: tag_params(sectors(:one), tag: 'Research')
    assert_redirected_to sector_url(sectors(:one))
    assert_equal ['Frontier'], sectors(:one).reload.tag_names
    assert_equal ['Frontier', 'Research'], regions(:one).reload.tag_names
  end

  test 'other campaign owners cannot add or remove tags' do
    record = sectors(:one)
    sign_in_as users(:two)
    post object_tags_url, params: tag_params(record, tag_list: 'New tag')
    assert_response :forbidden
    delete object_tags_url, params: tag_params(record, tag: 'Research')
    assert_response :forbidden
    assert_equal ['Frontier', 'Research'], record.reload.tag_names
  end

  test 'starmap loads a body editor and removes tags in the same frame' do
    record = gas_giants(:small)
    record.update!(star_system: star_systems(:in_one))
    frame = "starmap_tags_StellarObject_#{record.id}_analysis"
    get object_tags_url, params: tag_params(record, tag_context: 'analysis'), headers: { 'Turbo-Frame' => frame }
    assert_response :success
    assert_select 'turbo-frame[id=?]', frame
    assert_select 'button[aria-label="Remove Research"]'
    delete object_tags_url, params: tag_params(record, tag: 'Research', tag_context: 'analysis'), headers: { 'Turbo-Frame' => frame }
    assert_response :success
    assert_select 'turbo-frame[id=?]', frame
    assert_equal ['Frontier'], record.reload.tag_names
  end

  test 'system starmap editor includes individually removable body tags' do
    record = star_systems(:in_one)
    gas_giants(:small).update!(star_system: record)
    frame = "starmap_tags_StarSystem_#{record.id}_map"
    get object_tags_url, params: tag_params(record, tag_context: 'map'), headers: { 'Turbo-Frame' => frame }
    assert_response :success
    assert_select 'turbo-frame[id=?]', frame
    assert_select 'input[name=record_id][value=?]', gas_giants(:small).id.to_s
  end

  test 'another campaign owner cannot load starmap tag editors' do
    sign_in_as users(:two)
    get object_tags_url, params: tag_params(sectors(:one), tag_context: 'analysis')
    assert_response :forbidden
  end

  test 'record types are restricted to taggable map objects' do
    post object_tags_url, params: { record_type: 'Campaign', record_id: campaigns(:one).id, tag_list: 'New tag' }
    assert_response :not_found
  end

  test 'grid add returns to the grid it came from' do
    record = sectors(:one)
    post object_tags_url, params: tag_params(record, tag_list: 'Grid tag', return_to: '/sectors?q=a')
    assert_redirected_to '/sectors?q=a'
    assert_includes record.reload.tag_names, 'Grid tag'
  end

  test 'grid add ignores external return paths' do
    record = sectors(:one)
    ['https://evil.example/', '//evil.example/x'].each do |target|
      post object_tags_url, params: tag_params(record, tag_list: 'Grid tag', return_to: target)
      assert_redirected_to sector_path(record)
    end
  end

  test 'grids show a tags column and an add tag action' do
    sectors(:one).update!(tag_list: 'Visible')
    get sectors_url
    assert_response :success
    assert_select 'th', text: 'Tags'
    assert_select 'td [aria-label=Tags] a', text: 'Visible'
    assert_select 'td.actions-cell button[aria-label^="Add tag to"]'
    assert_select 'td.actions-cell dialog form[action=?]', object_tags_path
  end

  test 'grid add form breaks out of any enclosing turbo frame' do
    get sectors_url
    assert_select 'dialog form[data-turbo-frame="_top"]'
  end

  test 'grid chips can remove a tag and return to the grid' do
    record = sectors(:one)
    record.update!(tag_list: 'Keep, Drop')
    get sectors_url
    assert_select 'td [aria-label=Tags] form[action=?][data-turbo-frame="_top"] input[name=tag][value=Drop]', object_tags_path
    delete object_tags_url, params: tag_params(record, tag: 'Drop', return_to: '/sectors')
    assert_redirected_to '/sectors'
    assert_equal ['Keep'], record.reload.tag_names
  end

  test 'sector chart tiles show the sector tags' do
    sectors(:one).update!(tag_list: 'Chart tag')
    get sectors_url
    assert_select '[data-sectors-view-target=chartCell] [aria-label=Tags]', text: /Chart tag/
  end
end
