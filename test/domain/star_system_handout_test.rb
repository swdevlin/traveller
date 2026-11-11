require 'test_helper'

class StarSystemHandoutTest < ActiveSupport::TestCase
  setup do
    @campaign = campaigns(:one)
    @system = StarSystem.create!(name: 'Pernehoyn', parsec: parsecs(:one), player_notes: "Known to **traders**.\n\n- one\n- two",
                                 referee_notes: 'The ruins are a trap.')
    star = Star.create!(star_system: @system, colour: 'Yellow', stellar_type: 'G', stellar_subtype: 2, luminosity: 'V')
    @world = TerrestrialPlanet.create!(
      name: 'Pernehoyn Prime', orbiting: star, orbit: 1.0, size_code: '5', atmosphere_code: 6, hydrographics_code: 5,
      population_code: 7, government_code: 7, law_level_code: 8, tech_level_code: 5, starport_code: 'C',
      player_notes: 'Players know this.', referee_notes: 'Secret of the world.'
    )
    %w[In Ri].each do |code|
      trade_code = TradeCode.find_or_create_by!(code: code) { |tc| tc.definition = code }
      StellarObjectTradeCode.create!(stellar_object: @world, trade_code: trade_code)
    end
    @system.update!(main_world: @world)
  end

  def texts(handout)
    handout.items.grep(HandoutCanvas::Text).map(&:text)
  end

  test 'page size follows the campaign setting' do
    handout = StarSystemHandout.new(@system, @campaign)
    assert_equal [279.4, 215.9], [handout.width, handout.height]

    @campaign.handout_paper_size = 'a4'
    handout = StarSystemHandout.new(@system, @campaign)
    assert_equal [297.0, 210.0], [handout.width, handout.height]
  end

  test 'player handout shows the profile, the port briefing and commodity DMs but no referee notes' do
    all_text = texts(StarSystemHandout.new(@system, @campaign)).join("\n")

    assert_includes all_text, 'PERNEHOYN'
    assert_includes all_text, 'PUBLIC ADVISORY'
    assert_includes all_text, 'PORT BRIEFING'
    assert_includes all_text, 'traders'
    assert_includes all_text, 'Common Electronics'
    assert_not_includes all_text, 'The ruins are a trap.'
    assert_not_includes all_text, 'Secret of the world.'
    assert_not_includes all_text, 'CLASSIFIED RECORDS'
  end

  test 'player handout never shows the extinct sophont' do
    @world.update!(extinct_sophont: true)

    assert_not_includes texts(StarSystemHandout.new(@system, @campaign)).join(' '), 'Extinct'
  end

  test 'notes keep their markdown formatting' do
    items = StarSystemHandout.new(@system, @campaign).items.grep(HandoutCanvas::Text)

    assert items.any? { |t| t.text == 'traders' && t.weight == 'bold' }
    assert_equal 2, items.count { |t| t.text == '•' }
  end

  test 'handles a system with no main world' do
    @system.update!(main_world: nil)

    assert_includes texts(StarSystemHandout.new(@system, @campaign)).join(' '), 'No main world has been designated'
  end

  test 'accent colour follows the theme' do
    darrian = StarSystemHandout.new(@system, @campaign, theme: 'darrian').items
    vegan = StarSystemHandout.new(@system, @campaign, theme: 'vegan').items

    assert_not_equal darrian.grep(HandoutCanvas::Text).first.fill, vegan.grep(HandoutCanvas::Text).first.fill
  end

  test 'player profile sets population and other UWP codes beside their labels' do
    items = StarSystemHandout.new(@system, @campaign).items.grep(HandoutCanvas::Text)
    population = items.find { |t| t.text == 'POPULATION' }
    code = items.find { |t| t.text == '7' && t.weight == 'bold' }

    assert population
    assert code, 'expected the population code as its own bold run'
    assert_in_delta population.y, code.y, 0.001
    assert_operator code.x, :>, population.x
    assert items.none? { |t| t.text.start_with?('7 — ') }
  end

  test 'player profile shows the starport and hydrographics codes beside their labels' do
    items = StarSystemHandout.new(@system, @campaign).items.grep(HandoutCanvas::Text)

    %w[STARPORT HYDROGRAPHICS].each { |label| assert items.any? { |t| t.text == label }, label }
    assert items.any? { |t| t.text == 'C' && t.weight == 'bold' }, 'expected the starport code'
    assert items.any? { |t| t.text == '5' && t.weight == 'bold' }, 'expected the hydrographics code'
    assert items.none? { |t| t.text == 'LIQUID' }
  end

  test 'player profile folds starport charges into the starport cell and lists a native sophont only when there is one' do
    texts = StarSystemHandout.new(@system, @campaign).items.grep(HandoutCanvas::Text).map(&:text)

    assert texts.none? { |t| t.start_with?('Native sophont') }, 'no note when there is no native sophont'
    assert texts.none? { |t| t == 'NATIVE SOPHONT' }
    assert texts.none? { |t| %w[BERTHING REFINED\ FUEL UNREFINED\ FUEL].include?(t) }
  end

  test 'player profile shows size and atmosphere with their codes and no separate gravity or survival cells' do
    @world.update!(gravity: 0.68, diameter: 10_356, temperature: 290)
    items = StarSystemHandout.new(@system, @campaign).items.grep(HandoutCanvas::Text)

    %w[SIZE ATMOSPHERE].each { |label| assert items.any? { |t| t.text == label }, label }
    assert items.any? { |t| t.text == '6' && t.weight == 'bold' }, 'expected the atmosphere code'
    diameter = items.find { |t| t.text.end_with?('km') }
    gravity = items.find { |t| t.text.end_with?(' g') }
    assert gravity.y > diameter.y, 'gravity goes on its own line below the diameter'
    assert items.any? { |t| t.text == 'No special gear required' }
    assert diameter.text.start_with?('Diameter: '), 'diameter is labelled'
    assert gravity.text.start_with?('Gravity: '), 'gravity is labelled'
    temperature = items.find { |t| t.text == 'Temperature: 17°C' }
    assert temperature, 'temperature goes in the atmosphere cell, labelled'
    assert items.none? { |t| t.text == 'TEMPERATURE' }
    assert items.none? { |t| t.text.start_with?('Survival:') }
    assert items.none? { |t| %w[GRAVITY].include?(t.text) || t.text == 'SURVIVAL REQUIREMENT' }
  end

  test 'a short last row of profile cells uses the full width' do
    handout = StarSystemHandout.new(@system, @campaign)
    long = (['word'] * 12).join(' ')
    block = handout.send(:kv_cells, [%w[A x], %w[B x], %w[C x], ['D', long]], 150.0, count: 3)

    assert_equal 1, block.items.count { |item| item.is_a?(HandoutCanvas::Text) && item.text.include?('word') }
  end

  test 'notes are not headed with the system name' do
    @world.update!(player_notes: nil)
    items = StarSystemHandout.new(@system, @campaign).items.grep(HandoutCanvas::Text)

    assert items.any? { |t| t.text == 'traders' }
    assert items.none? { |t| t.text == 'Pernehoyn' }, 'no heading naming the system above its notes'
  end

  test 'the main world is named in the notes only when the system has notes too' do
    with_both = StarSystemHandout.new(@system, @campaign).items.grep(HandoutCanvas::Text)
    assert with_both.any? { |t| t.text == 'Pernehoyn Prime' && t.weight == 'bold' }

    @system.update!(player_notes: nil)
    world_only = StarSystemHandout.new(@system, @campaign).items.grep(HandoutCanvas::Text)
    assert world_only.none? { |t| t.text == 'Pernehoyn Prime' }
    assert world_only.any? { |t| t.text.include?('Players') }
  end

  test 'population shows the principal city and the capitals, with short figures' do
    @world.update!(population: (@world.population || {}).merge('censusPopulation' => 3_300_000_000))
    City.create!(stellar_object: @world, name: 'Alpha', population: 3_300_000)
    City.create!(stellar_object: @world, name: 'Beta', population: 1_000_000, capital_designation: 'Cw')
    City.create!(stellar_object: @world, name: 'Gamma', population: 450_000, capital_designation: 'Cr')
    City.create!(stellar_object: @world, name: 'Delta', population: 800_000)
    texts = StarSystemHandout.new(@system, @campaign).items.grep(HandoutCanvas::Text).map(&:text)

    assert_includes texts, '3.3 billion'
    assert_includes texts, 'Principal city: Alpha 3.3M'
    assert_includes texts, 'World capital: Beta 1M'
    assert_includes texts, 'Regional capital: Gamma 450K'
    assert texts.none? { |t| t.include?('Delta') }, 'only the principal city and capitals are listed'
  end

  test 'a capital that is also the largest city is annotated rather than repeated' do
    City.create!(stellar_object: @world, name: 'Alpha', population: 3_300_000, capital_designation: 'Cn')
    texts = StarSystemHandout.new(@system, @campaign).items.grep(HandoutCanvas::Text).map(&:text)

    assert_includes texts.join(' '), 'Principal city: Alpha 3.3M (national capital)'
    assert_equal 1, texts.count { |t| t.include?('Alpha') }
  end

  test 'player profile lists the UWP in its standard order' do
    order = ['STARPORT', 'SIZE', 'ATMOSPHERE', 'HYDROGRAPHICS', 'POPULATION', 'GOVERNMENT', 'LAW LEVEL', 'TECH LEVEL']
    texts = StarSystemHandout.new(@system, @campaign).items.grep(HandoutCanvas::Text).map(&:text)
    labels = texts.select { |text| order.include?(text) }

    assert_operator labels.size, :>=, 4
    assert_equal labels.sort_by { |text| order.index(text) }, labels
    assert_not_includes texts, 'ORBIT'
  end

  test 'the year and day lengths go under the main world on the schematic, with equal weight' do
    @world.update!(period: 365.0, sidereal_day: 23.5)
    items = StarSystemHandout.new(@system, @campaign).items.grep(HandoutCanvas::Text)
    year = items.find { |t| t.text.start_with?('Year ') }
    day = items.find { |t| t.text.start_with?('Day ') }
    heading = items.find { |t| t.text == 'PLANETARY CARTOGRAPHY' }

    assert year && day, 'expected a Year and a Day line'
    assert_equal year.size, day.size
    assert_equal year.fill, day.fill
    assert_in_delta year.x, day.x, 0.001
    assert_operator day.y, :>, year.y
    assert_operator day.y, :<, heading.y, 'within the schematic, above the cartography section'
  end

  test 'fuel costs read refined / unrefined, with a hyphen where one is not available' do
    texts = StarSystemHandout.new(@system, @campaign).items.grep(HandoutCanvas::Text).map(&:text)

    assert_includes texts, 'Fuel cost: - / -'
    assert_includes texts, 'Berthing -'
  end

  test 'trade codes are set as bold accent codes followed by their meanings' do
    items = StarSystemHandout.new(@system, @campaign).items.grep(HandoutCanvas::Text)
    code = items.find { |t| t.text == 'In' && t.weight == 'bold' }
    meaning = items.find { |t| t.text == 'In' && t.weight.nil? }

    assert code, 'expected the code in bold'
    assert_equal code.fill, items.find { |t| t.text == 'PLANETARY PROFILE' }.fill, 'in the accent colour'
    assert_in_delta code.y, meaning.y, 0.001
    assert_operator meaning.x, :>, code.x
  end

  test 'bases are listed by name in the starport cell' do
    naval = Facility.find_or_create_by!(code: 'N') { |f| f.name = 'Naval base' }
    scout = Facility.find_or_create_by!(code: 'S') { |f| f.name = 'Scout base' }
    [naval, scout].each { |facility| StarSystemFacility.create!(star_system: @system, facility: facility) }
    texts = StarSystemHandout.new(@system, @campaign).items.grep(HandoutCanvas::Text).map(&:text)

    assert_includes texts, 'Bases: Naval base, Scout base'
    assert texts.none? { |t| t.start_with?('Bases: N') && t.length < 12 }, 'no bare codes in the header'
  end

  test 'a travel zone is shown as a banner in the zone colour in the header, without the trade codes' do
    zone = TravelZone.create!(code: 'A', name: 'Amber', colour: '#eab308')
    @system.update!(travel_zone: zone)
    handout = StarSystemHandout.new(@system, @campaign)
    items = handout.items
    texts = items.grep(HandoutCanvas::Text)
    header_limit = StarSystemHandout::MARGIN + StarSystemHandout::HEADER_HEIGHT
    title = texts.find { |t| t.text == 'AMBER ZONE' }

    assert title && title.y < header_limit, 'the zone name in the header'
    assert texts.any? { |t| t.text == 'TRAVEL ADVISORY' }
    uwp = texts.find { |t| t.text == @system.main_world_uwp }
    assert_operator title.y, :>, uwp.y, 'under the UWP'
    assert_equal uwp.x, title.x, 'right-aligned with the UWP'
    assert items.grep(HandoutCanvas::Rect).any? { |r| r.fill == '#eab308' }, 'a bar in the zone colour'
    assert_not_equal '#eab308', title.fill, 'the text is darkened to be readable on white'
    assert HandoutPalette.contrast(HandoutPalette.parse(title.fill), HandoutPalette::WHITE) >= HandoutPalette::MIN_CONTRAST
    assert texts.none? { |t| t.text.start_with?('Trade:') }
  end

  test 'no travel zone banner without a travel zone' do
    texts = StarSystemHandout.new(@system, @campaign).items.grep(HandoutCanvas::Text).map(&:text)

    assert_not_includes texts, 'TRAVEL ADVISORY'
  end

  test 'filename names the system' do
    assert_equal 'pernehoyn-handout.pdf', StarSystemHandout.new(@system, @campaign).filename
  end
end
