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

  # trade_codes / trade_codes_string

  test 'trade_codes delegates to main_world trade_codes' do
    star_system = StarSystem.create!(name: 'Trade World', parsec: parsecs(:one))
    star = Star.create!(
      star_system: star_system,
      colour: 'Yellow', stellar_type: 'G', stellar_subtype: 2, luminosity: 'V'
    )
    main_world = TerrestrialPlanet.create!(
      orbiting: star, orbit: 1.0,
      size_code: '5', atmosphere_code: 6, hydrographics_code: 5
    )
    StellarObjectTradeCode.create!(stellar_object: main_world, trade_code: trade_codes(:tc2))
    StellarObjectTradeCode.create!(stellar_object: main_world, trade_code: trade_codes(:tc1))
    star_system.update!(main_world: main_world)

    assert_equal [trade_codes(:tc1), trade_codes(:tc2)], star_system.trade_codes.order(:code).to_a
    assert_equal 'T1 T2', star_system.trade_codes_string
  end

  test 'trade_codes returns empty when no main_world is set' do
    star_system = StarSystem.create!(name: 'No Main World', parsec: parsecs(:one))

    assert_equal [], star_system.trade_codes.to_a
    assert_equal '', star_system.trade_codes_string
  end

  # sector_capital? / subsector_capital?

  def build_star_system_with_main_world_trade_codes(*codes)
    star_system = StarSystem.create!(name: 'Capital World', parsec: parsecs(:one))
    star = Star.create!(
      star_system: star_system,
      colour: 'Yellow', stellar_type: 'G', stellar_subtype: 2, luminosity: 'V'
    )
    main_world = TerrestrialPlanet.create!(
      orbiting: star, orbit: 1.0,
      size_code: '5', atmosphere_code: 6, hydrographics_code: 5
    )
    codes.each { |trade_code| StellarObjectTradeCode.create!(stellar_object: main_world, trade_code: trade_code) }
    star_system.update!(main_world: main_world)
    star_system
  end

  test 'sector_capital? is true when the main world has the Cs trade code' do
    star_system = build_star_system_with_main_world_trade_codes(trade_codes(:sector_capital))

    assert star_system.sector_capital?
    assert_not star_system.subsector_capital?
  end

  test 'subsector_capital? is true when the main world has the Cp trade code' do
    star_system = build_star_system_with_main_world_trade_codes(trade_codes(:subsector_capital))

    assert star_system.subsector_capital?
    assert_not star_system.sector_capital?
  end

  test 'sector_capital? and subsector_capital? are false without the matching trade code' do
    star_system = build_star_system_with_main_world_trade_codes(trade_codes(:tc1))

    assert_not star_system.sector_capital?
    assert_not star_system.subsector_capital?
  end

  test 'sector_capital? and subsector_capital? are false with no main_world' do
    star_system = StarSystem.create!(name: 'No Main World', parsec: parsecs(:one))

    assert_not star_system.sector_capital?
    assert_not star_system.subsector_capital?
  end
end
