require 'test_helper'

class StarSystemTest < ActiveSupport::TestCase
  # effective_language

  test 'effective_language returns own language when set' do
    campaign = campaigns(:one)
    star_system = star_systems(:in_one)
    star_system.language = 'japanese'
    assert_equal 'japanese', star_system.effective_language(campaign)
  end

  test 'effective_language falls back through subsector then sector' do
    campaign = campaigns(:one)
    star_system = star_systems(:in_one)
    star_system.parsec.subsector.update!(language: 'korean')
    assert_equal 'korean', star_system.effective_language(campaign)
  end

  test 'effective_language falls back to campaign default' do
    campaign = campaigns(:one)
    campaign.default_language = 'solomani'
    star_system = star_systems(:in_one)
    assert_equal 'solomani', star_system.effective_language(campaign)
  end

  test 'effective_language own language overrides subsector language' do
    campaign = campaigns(:one)
    star_system = star_systems(:in_one)
    star_system.parsec.subsector.update!(language: 'aslan')
    star_system.language = 'zdetl'
    assert_equal 'zdetl', star_system.effective_language(campaign)
  end

  # with_native_sophont scope

  test 'with_native_sophont returns star systems that have a stellar object with native_sophont' do
    star_system = StarSystem.create!(name: 'Native World', parsec: parsecs(:one))
    star = Star.create!(
      star_system: star_system,
      colour: 'Yellow', stellar_type: 'G', stellar_subtype: 2, luminosity: 'V'
    )
    TerrestrialPlanet.create!(
      orbiting: star, orbit: 1.0,
      size_code: '5', atmosphere_code: 6, hydrographics_code: 5,
      native_sophont: true
    )

    assert_includes StarSystem.with_native_sophont, star_system
  end

  test 'with_native_sophont excludes star systems with no native sophonts' do
    star_system = StarSystem.create!(name: 'Barren System', parsec: parsecs(:one))
    star = Star.create!(
      star_system: star_system,
      colour: 'Yellow', stellar_type: 'G', stellar_subtype: 2, luminosity: 'V'
    )
    TerrestrialPlanet.create!(
      orbiting: star, orbit: 1.0,
      size_code: '5', atmosphere_code: 6, hydrographics_code: 5,
      native_sophont: false
    )

    assert_not_includes StarSystem.with_native_sophont, star_system
  end
end
