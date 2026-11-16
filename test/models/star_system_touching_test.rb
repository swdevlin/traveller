# frozen_string_literal: true

require 'test_helper'

# What is cached against a star system's updated_at (the detail JSON, the maps) is only
# as fresh as updated_at is, so each change a system's detail shows must bump it.
class StarSystemTouchingTest < ActiveSupport::TestCase
  setup do
    @sector = Sector.create!(name: 'Touching Sector', x: 91, y: 91, abbreviation: 'Tch')
    @parsec = Parsec.create!(sector: @sector, x: 91 * 32, y: 91 * 40)
    @system = StarSystem.create!(name: 'Touching System', parsec: @parsec, known: true)
    @star = Star.create!(star_system: @system, colour: 'Yellow', stellar_type: 'G', stellar_subtype: 2, luminosity: 'V')
    @planet = TerrestrialPlanet.create!(
      size_code: '5', atmosphere_code: 6, hydrographics_code: 5, population_code: 6, government_code: 5,
      law_level_code: 5, tech_level_code: 8, starport_code: 'A', orbiting: @star, orbit: 1.0
    )
    @system.update!(main_world: @planet)
  end

  # Runs the block, and asserts that the system's updated_at moved on from a stale value.
  def assert_touches_system(message = nil)
    stale = 1.day.ago.change(usec: 0)
    StarSystem.where(id: @system.id).update_all(updated_at: stale)
    yield
    assert_operator @system.reload.updated_at, :>, stale, message || 'the system was not touched'
  end

  def assert_leaves_system_alone
    stale = 1.day.ago.change(usec: 0)
    StarSystem.where(id: @system.id).update_all(updated_at: stale)
    yield
    assert_equal stale, @system.reload.updated_at, 'the system was touched'
  end

  # ---- its own tree

  test 'saving a body touches the system' do
    assert_touches_system { @planet.update!(name: 'Renamed') }
  end

  test 'saving a moon touches the system' do
    moon = Moon.create!(name: 'Moon', orbiting: @planet, orbit: 2, au: 0.01, size_code: 'S')
    assert_touches_system { moon.update!(name: 'Renamed') }
  end

  test 'a city touches the system when it is added, changed and removed' do
    city = nil
    assert_touches_system('adding') { city = City.create!(stellar_object: @planet, name: 'Port', population: 1000) }
    assert_touches_system('changing') { city.update!(population: 2000) }
    assert_touches_system('removing') { city.destroy! }
  end

  test 'a planet map touches the system' do
    assert_touches_system { @planet.store_map(SAMPLE_SVG) }
  end

  test 'a trade code touches the system' do
    assert_touches_system { @planet.trade_codes = [trade_codes(:tc1)] }
  end

  test 'a base touches the system' do
    assert_touches_system { @system.facilities << facilities(:one) }
  end

  # ---- tags

  test 'adding and removing a tag on a body touches the system' do
    assert_touches_system('adding') { @planet.update!(tag_names: ['one']) }
    assert_touches_system('removing') { @planet.tag_names = [] }
  end

  test 'adding and removing a tag on the system itself touches the system' do
    assert_touches_system('adding') { @system.tag_names = ['one'] }
    assert_touches_system('removing') { @system.tag_names = [] }
  end

  # ---- rows shared between systems

  test 'editing a shared row touches the systems' do
    @system.update!(allegiance: allegiances(:one))  # an allegiance touches only its own systems
    [governments(:one), law_levels(:one), tech_levels(:one), trade_codes(:tc1), allegiances(:one)].each do |row|
      assert_touches_system(row.class.name) { row.update!(updated_at: Time.current) }
    end
  end

  test 'renaming a tag touches the systems' do
    tag = Tag.create!(name: 'before')
    assert_touches_system { tag.update!(name: 'after') }
  end

  test 'editing a base touches only the systems that have it' do
    base = facilities(:two)
    assert_leaves_system_alone { base.update!(name: 'Renamed base') }

    @system.facilities << facilities(:one)
    assert_touches_system { facilities(:one).update!(name: 'Renamed base') }
  end

  test 'renaming the sector touches its systems' do
    assert_touches_system { @sector.update!(name: 'Renamed Sector') }
  end

  test 'the sector being touched by its parsecs does not touch every system in it' do
    assert_leaves_system_alone { @sector.touch }
  end

  test 'editing another sector leaves the system alone' do
    assert_leaves_system_alone { sectors(:one).update!(name: 'Elsewhere') }
  end

  # ---- writes that skip callbacks

  test 'raising the survey index by a jump touches the system, and doing nothing does not' do
    jump = JumpLog.new(to_parsec_id: @parsec.id)
    @system.update!(survey_index: 3)

    assert_touches_system { jump.raise_destination_survey_index }
    assert_equal JumpLog::DESTINATION_SURVEY_INDEX, @system.reload.survey_index

    assert_leaves_system_alone { jump.raise_destination_survey_index }
  end
end
