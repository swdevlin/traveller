require 'test_helper'

class MoonsControllerTest < AuthenticatedIntegrationTest
  setup do
    @planet = stellar_objects(:moons_test_gas_giant)
  end

  test 'should get new with every section of the moon edit form as a tab' do
    get new_stellar_object_moon_url(@planet)

    assert_response :success
    assert_select "button[data-tabs-target='tab']", Moon.new.edit_sections.size
    assert_select "[data-tabs-target='panel']", Moon.new.edit_sections.size
    %w[orbit size_code period starport_code atmosphere_code hydrographics_code].each do |field|
      assert_select "[name='stellar_object[#{field}]']", 1, "expected a #{field} field"
    end
  end

  test 'new moon page links to the moon edit help' do
    get new_stellar_object_moon_url(@planet)

    assert_select "a[href='#{help_page_path('moon_edit')}']"
  end

  test 'editing a moon links to the moon edit help' do
    get edit_stellar_object_url(stellar_objects(:moons_test_significant_moon))

    assert_select "a[href='#{help_page_path('moon_edit')}']"
  end

  test 'editing a moon is one form with a tab per section, so selections survive tab switches' do
    get edit_stellar_object_url(stellar_objects(:moons_test_significant_moon))

    assert_select "button[data-tabs-target='tab']", Moon.new.edit_sections.size
    assert_select "[data-tabs-target='panel']", Moon.new.edit_sections.size
    assert_select 'a.uwp-tab-btn', 0
  end

  test 'moon edit help page states the orbit is in planetary diameters' do
    get help_page_url('moon_edit')

    assert_response :success
    assert_includes response.body, 'planetary diameters'
  end

  test 'should create moon orbiting the planet' do
    assert_difference('Moon.count') do
      post stellar_object_moons_url(@planet), params: { stellar_object: { name: 'New moon', orbit: 1.5, size_code: '3', starport_code: 'X', period: 2.5, atmosphere_code: 6 } }
    end

    moon = Moon.order(:id).last
    assert_equal @planet, moon.orbiting
    assert_equal @planet.star_system_id, moon.star_system_id
    assert_equal '3', moon.size_code
    assert_equal 2.5, moon.period
    assert_equal 6, moon.atmosphere_code
    assert_redirected_to stellar_object_url(@planet)
  end

  test 'rejects a moon without a starport' do
    assert_no_difference('Moon.count') do
      post stellar_object_moons_url(@planet), params: { stellar_object: { name: 'No port', orbit: 1.5, size_code: '3' } }
    end

    assert_response :unprocessable_entity
  end

  test 'creating a moon calculates its orbit position from the planet' do
    @planet.update_columns(orbit_x: 7.5e8, orbit_y: -2.0e8)
    post stellar_object_moons_url(@planet), params: { stellar_object: { name: 'Placed moon', orbit: 4, eccentricity: 0.2, size_code: '3', starport_code: 'X' } }

    moon = Moon.order(:id).last
    assert_not_nil moon.orbit_x
    assert_not_nil moon.orbit_y
    distance = Math.hypot(moon.orbit_x - 7.5e8, moon.orbit_y + 2.0e8)
    semi_major_axis = 4 * @planet.diameter
    assert_operator distance, :>=, (semi_major_axis * 0.8) - 1e-6
    assert_operator distance, :<=, (semi_major_axis * 1.2) + 1e-6
  end

  test 'saving a new moon renumbers only the planet\'s moons by orbit' do
    @planet.update_column(:orbit_sequence, 'ZZ')

    post stellar_object_moons_url(@planet), params: { stellar_object: { name: 'Inner moon', orbit: 0.5, size_code: '3', starport_code: 'X' } }

    moons = @planet.moons.order(:orbit)
    assert_equal 'Inner moon', moons.first.name
    assert_equal (1..moons.count).map { |i| "ZZ.#{i}" }, moons.map(&:orbit_sequence)
    assert_equal 'ZZ', @planet.reload.orbit_sequence
  end

  test 'should not create moon without a size' do
    assert_no_difference('Moon.count') do
      post stellar_object_moons_url(@planet), params: { stellar_object: { orbit: 1.5 } }
    end

    assert_response :unprocessable_entity
  end

  test 'deleting a moon renumbers the remaining moons of its planet' do
    @planet.update_column(:orbit_sequence, 'ZZ')
    %w[One Two Three].each_with_index do |name, i|
      post stellar_object_moons_url(@planet), params: { stellar_object: { name: name, orbit: i + 1, size_code: '3', starport_code: 'X' } }
    end
    doomed = @planet.moons.find_by(name: 'One')

    assert_difference('Moon.count', -1) do
      delete stellar_object_url(doomed), headers: { 'HTTP_REFERER' => stellar_object_url(@planet) }
    end

    remaining = @planet.moons.order(:orbit).reject { |m| m.id == doomed.id }
    assert_equal (1..remaining.size).map { |i| "ZZ.#{i}" }, remaining.map(&:orbit_sequence)
  end

  test 'moons table has edit and delete actions for a moon' do
    moon = stellar_objects(:moons_test_significant_moon)

    get stellar_object_url(@planet)

    assert_select "a[href='#{edit_stellar_object_path(moon)}'][title='Edit moon']"
    assert_select "form[action='#{stellar_object_path(moon)}'] button[title='Delete moon']"
  end

  test 'moons table shows each moon\'s orbit sequence' do
    moon = stellar_objects(:moons_test_significant_moon)
    moon.update_column(:orbit_sequence, 'ZZ.1')

    get stellar_object_url(@planet)

    assert_select 'th', text: 'Seq'
    assert_select 'td', text: 'ZZ.1'
  end

  test 'creating a moon leaves its position blank when the planet has none' do
    post stellar_object_moons_url(@planet), params: { stellar_object: { name: 'Unplaced moon', orbit: 4, size_code: '3', starport_code: 'X' } }

    moon = Moon.find_by!(name: 'Unplaced moon')
    assert_nil moon.orbit_x
    assert_nil moon.orbit_y
  end
end
