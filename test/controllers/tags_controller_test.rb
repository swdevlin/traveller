require 'test_helper'

class TagsControllerTest < AuthenticatedIntegrationTest
  setup do
    @objects = [sectors(:one), subsectors(:subsector_1_1), star_systems(:in_one), StellarObject.first, regions(:one)]
    @objects.each { |object| object.update!(tag_list: 'Research, Frontier') }
  end

  test 'registry lists existing tags once and links from data cores' do
    get tags_url
    assert_response :success
    assert_select 'tbody tr', count: 2
    assert_select 'td.actions-cell a[aria-label="Edit Research"] i.fa-pen-to-square'
    assert_select 'td.actions-cell button[aria-label="Delete Research"] i.fa-trash'
    assert_select 'input[name=replacement]', count: 0
    get data_cores_url
    assert_select 'a[href=?]', tags_path, text: /Tags/
  end

  test 'tag names and badges link to the summary page' do
    get tags_url
    assert_select 'tbody a[href=?]', tag_path(name: 'Research'), text: 'Research'
    get star_system_url(star_systems(:in_one))
    assert_response :success
    assert_select '[aria-label=Tags] a[href=?]', tag_path(name: 'Research'), text: 'Research'
  end

  test 'show counts direct assignments by object type without counting other tags' do
    @objects.each { |object| object.update!(tag_list: 'Unique summary tag') }
    sectors(:two).update!(tag_list: 'Other')
    get tag_url(name: 'Unique summary tag')
    assert_response :success
    assert_select '.page-title', text: 'Unique summary tag'
    assert_select '[aria-label="Tagged object counts"] > div', count: 5
    assert_select '[aria-label="Tagged object counts"] .text-fg-bright', text: '1', count: 5
    assert_select '.page-body .text-fg-bright', text: '5', count: 1
    assert_select 'a[href=?]', edit_tag_path(name: 'Unique summary tag'), text: 'Edit'
  end

  test 'unknown tags have no show page' do
    get tag_url(name: 'Unknown tag')
    assert_response :not_found
  end

  test 'special characters in tag names round trip through links and the summary page' do
    name = 'Research / A&B <test>'
    sectors(:one).update!(tag_names: [name])
    get tags_url
    assert_select 'tbody a[href=?]', tag_path(name: name), text: name
    get tag_url(name: name)
    assert_response :success
    assert_select '.page-title', text: name
    assert_select 'test', count: 0
  end

  test 'tagged object detail pages display tags once in the right sidebar' do
    gas_giants(:small).update!(star_system: star_systems(:in_one))
    records_and_paths = [
      [sectors(:one), sector_url(sectors(:one))],
      [subsectors(:subsector_1_1), subsector_url(subsectors(:subsector_1_1))],
      [star_systems(:in_one), star_system_url(star_systems(:in_one))],
      [gas_giants(:small), stellar_object_url(gas_giants(:small))],
      [stars(:star_one), star_url(stars(:star_one))],
      [regions(:one), region_url(regions(:one))]
    ]
    records_and_paths.each do |record, path|
      record.update!(tag_list: 'Sidebar tag')
      get path
      assert_response :success
      assert_select '.page-side [aria-label="Object tags"] a[href=?]', tag_path(name: 'Sidebar tag'), text: 'Sidebar tag', count: 1
      # Grid rows list their own tags; the page's own tags only appear in the sidebar.
      assert_empty css_select('.page-main [aria-label=Tags]').reject { |node| node.ancestors('td').any? }
    end
  end

  test 'registry paginates tags alphabetically' do
    sectors(:one).update!(tag_list: (1..13).map { |i| 'Tag %02d' % i }.join(', '))
    get tags_url
    assert_response :success
    assert_select 'tbody tr', count: 10
    assert_select 'nav.pagy', count: 1
    get tags_url(page: 2)
    assert_response :success
    assert_select 'tbody tr', count: 5
    assert_select 'tbody tr:first-child td:first-child', text: 'Tag 09'
  end

  test 'edit form preserves the registry page and submitted invalid name' do
    get edit_tag_url(name: 'Research', page: 2)
    assert_response :success
    assert_select 'input[name=replacement][value=Research]'
    assert_select 'input[name=page][value="2"]'
    patch tags_url, params: { name: 'Research', replacement: 'Invalid, Name', page: 2 }
    assert_response :unprocessable_entity
    assert_select 'input[name=replacement][value="Invalid, Name"]'
  end

  test 'deleting the only tag on the last page returns to the previous page' do
    @objects.each { |object| object.update!(tag_list: '') }
    Tag.destroy_all
    sectors(:one).update!(tag_list: (1..11).map { |i| 'Tag %02d' % i }.join(', '))
    delete tags_url, params: { name: 'Tag 11', page: 2 }
    assert_redirected_to tags_url(page: 1)
    follow_redirect!
    assert_response :success
    assert_select 'tbody tr', count: 10
  end

  test 'object editors offer tags from all object types' do
    get edit_star_system_url(star_systems(:in_one))
    assert_response :success
    assert_select '[data-controller=tag-picker]' do
      catalog = JSON.parse(css_select('[data-tag-picker-tags-value]').first['data-tag-picker-tags-value'])
      assert_includes catalog, 'Research'
      assert_includes catalog, 'Frontier'
      assert_select '[data-tag-picker-target=suggestion][hidden]'
      assert_select 'input[data-action*="keydown->tag-picker#keydown"]'
      assert_select 'input[name="star_system[tag_list]"]'
    end
  end

  test 'rename merges tags across all object types' do
    patch tags_url, params: { name: 'Research', replacement: ' Frontier ' }
    assert_redirected_to tags_url
    @objects.each { |object| assert_equal ['Frontier'], object.reload.tag_names }
  end

  test 'invalid rename leaves all assignments untouched' do
    patch tags_url, params: { name: 'Research', replacement: 'Invalid, Name' }
    assert_response :unprocessable_entity
    @objects.each { |object| assert_equal ['Frontier', 'Research'], object.reload.tag_names }
  end

  test 'delete removes only the selected tag from all object types' do
    delete tags_url, params: { name: 'Research' }
    assert_redirected_to tags_url
    @objects.each { |object| assert_equal ['Frontier'], object.reload.tag_names }
    assert_not_includes Tag.names, 'Research'
  end

  test 'another campaign owner cannot manage these tags' do
    sign_in_as users(:two)
    patch tags_url, params: { name: 'Research', replacement: 'Changed' }
    assert_response :forbidden
    delete tags_url, params: { name: 'Research' }
    assert_response :forbidden
    @objects.each { |object| assert_equal ['Frontier', 'Research'], object.reload.tag_names }
  end
end
