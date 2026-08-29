require 'test_helper'

class SystemQueryBuilderTest < ActiveSupport::TestCase
  def build_star_system(parsec: parsecs(:one), **world_attrs)
    star_system = StarSystem.create!(name: "System #{SecureRandom.hex(4)}", parsec: parsec)
    star = Star.create!(
      star_system: star_system,
      colour: 'Yellow', stellar_type: 'G', stellar_subtype: 2, luminosity: 'V'
    )
    defaults = {
      size_code: '5', atmosphere_code: 6, hydrographics_code: 5,
      population_code: 6, government_code: 5, law_level_code: 5,
      tech_level_code: 8, starport_code: 'A'
    }
    main_world = TerrestrialPlanet.create!(defaults.merge(world_attrs).merge(orbiting: star, orbit: 1.0))
    star_system.update!(main_world: main_world)
    star_system
  end

  def relation_for(field:, operator:, values:, negate: false)
    SystemQueryBuilder.new(
      { groups: [[{ field: field, operator: operator, negate: negate, values: values }]] }
    ).relation
  end

  test 'relation with no groups returns everything (unlike SurveyOverlay#matches?)' do
    star_system = build_star_system
    assert_includes SystemQueryBuilder.new({}).relation, star_system
  end

  test 'eq operator on a UWP jsonb integer field' do
    matching = build_star_system(tech_level_code: 12)
    other = build_star_system(tech_level_code: 3)

    relation = relation_for(field: 'tech_level', operator: 'eq', values: ['C'])

    assert_includes relation, matching
    assert_not_includes relation, other
  end

  test 'between operator on a UWP jsonb integer field' do
    low = build_star_system(population_code: 2)
    mid = build_star_system(population_code: 5)
    high = build_star_system(population_code: 9)

    relation = relation_for(field: 'population', operator: 'between', values: %w[4 6])

    assert_not_includes relation, low
    assert_includes relation, mid
    assert_not_includes relation, high
  end

  test 'starport rank is reversed so gt C matches A and B but not D, E, X' do
    a = build_star_system(starport_code: 'A')
    b = build_star_system(starport_code: 'B')
    c = build_star_system(starport_code: 'C')
    d = build_star_system(starport_code: 'D')
    x = build_star_system(starport_code: 'X')

    relation = relation_for(field: 'starport', operator: 'gt', values: ['C'])

    assert_includes relation, a
    assert_includes relation, b
    assert_not_includes relation, c
    assert_not_includes relation, d
    assert_not_includes relation, x
  end

  test 'size field compares the size_code column by rank' do
    small = build_star_system(size_code: '2')
    large = build_star_system(size_code: 'F')

    relation = relation_for(field: 'size', operator: 'gte', values: ['A'])

    assert_not_includes relation, small
    assert_includes relation, large
  end

  test 'survey_index and gas_giant_count compare real star_systems columns' do
    star_system = build_star_system
    star_system.update!(survey_index: 9, gas_giant_count: 3)

    assert_includes relation_for(field: 'survey_index', operator: 'gte', values: ['5']), star_system
    assert_not_includes relation_for(field: 'survey_index', operator: 'gte', values: ['10']), star_system
    assert_includes relation_for(field: 'gas_giant_count', operator: 'eq', values: ['3']), star_system
  end

  test 'known, native_sophont and extinct_sophont are boolean columns' do
    star_system = build_star_system
    star_system.update!(known: true, native_sophont: true, extinct_sophont: false)

    assert_includes relation_for(field: 'known', operator: 'eq', values: ['true']), star_system
    assert_includes relation_for(field: 'native_sophont', operator: 'eq', values: ['true']), star_system
    assert_not_includes relation_for(field: 'extinct_sophont', operator: 'eq', values: ['true']), star_system
  end

  test 'importance reads main_world economics data' do
    star_system = build_star_system
    star_system.main_world.update!(data: star_system.main_world.data.merge('economics' => { 'importance' => 3 }))

    assert_includes relation_for(field: 'importance', operator: 'eq', values: ['3']), star_system
    assert_not_includes relation_for(field: 'importance', operator: 'eq', values: ['2']), star_system
  end

  test 'base_count counts star_system_facilities' do
    star_system = build_star_system
    StarSystemFacility.create!(star_system: star_system, facility: facilities(:one))
    StarSystemFacility.create!(star_system: star_system, facility: facilities(:two))
    other = build_star_system

    relation = relation_for(field: 'base_count', operator: 'eq', values: ['2'])

    assert_includes relation, star_system
    assert_not_includes relation, other
  end

  test 'star_count counts every Star row for the system' do
    star_system = build_star_system
    Star.create!(star_system: star_system, orbiting: star_system.primary_star, colour: 'Red', stellar_type: 'M', stellar_subtype: 5, orbit: 40.0)
    other = build_star_system

    relation = relation_for(field: 'star_count', operator: 'eq', values: ['2'])

    assert_includes relation, star_system
    assert_not_includes relation, other
  end

  test 'primary_star eq and one_of compare the primary star stellar_type' do
    g_type = build_star_system
    m_type = build_star_system
    m_type.primary_star.update!(stellar_type: 'M')

    relation = relation_for(field: 'primary_star', operator: 'one_of', values: %w[G])

    assert_includes relation, g_type
    assert_not_includes relation, m_type
  end

  test 'primary_star_class eq compares the primary star stellar_class' do
    giant = build_star_system
    giant.primary_star.update!(stellar_class: 'III')
    main_sequence = build_star_system
    main_sequence.primary_star.update!(stellar_class: 'V')

    relation = relation_for(field: 'primary_star_class', operator: 'eq', values: ['III'])

    assert_includes relation, giant
    assert_not_includes relation, main_sequence
  end

  test 'primary_star_class gt ranks by luminosity, most to least luminous' do
    giant = build_star_system
    giant.primary_star.update!(stellar_class: 'III')
    main_sequence = build_star_system
    main_sequence.primary_star.update!(stellar_class: 'V')

    relation = relation_for(field: 'primary_star_class', operator: 'gt', values: ['III'])

    assert_not_includes relation, giant
    assert_includes relation, main_sequence
  end

  test 'bases has and has_one_of match systems with a facility whose code is in values' do
    star_system = build_star_system
    StarSystemFacility.create!(star_system: star_system, facility: facilities(:one))
    other = build_star_system

    relation = relation_for(field: 'bases', operator: 'has', values: [facilities(:one).code])

    assert_includes relation, star_system
    assert_not_includes relation, other
  end

  test 'allegiance eq and one_of compare via the allegiance code' do
    im = build_star_system
    im.update!(allegiance: allegiances(:one))
    zh = build_star_system
    zh.update!(allegiance: allegiances(:two))

    relation = relation_for(field: 'allegiance', operator: 'one_of', values: [allegiances(:one).code])

    assert_includes relation, im
    assert_not_includes relation, zh
  end

  test 'sector field compares the parsec sector id' do
    in_sector = build_star_system(parsec: parsecs(:one))
    in_other_sector = build_star_system(parsec: parsecs(:two))

    relation = relation_for(field: 'sector', operator: 'eq', values: [sectors(:one).id.to_s])

    assert_includes relation, in_sector
    assert_not_includes relation, in_other_sector
  end

  test 'subsector field resolves a parsec x/y bounding box for the subsector' do
    in_subsector = build_star_system(parsec: parsecs(:one))

    other_parsec = Parsec.create!(sector: sectors(:one), x: parsecs(:one).x + 8, y: parsecs(:one).y)
    outside_subsector = build_star_system(parsec: other_parsec)

    relation = relation_for(field: 'subsector', operator: 'eq', values: [subsectors(:subsector_1_1).id.to_s])

    assert_includes relation, in_subsector
    assert_not_includes relation, outside_subsector
  end

  test 'negate flips the condition' do
    matching = build_star_system(starport_code: 'A')
    other = build_star_system(starport_code: 'B')

    relation = relation_for(field: 'starport', operator: 'eq', values: ['A'], negate: true)

    assert_not_includes relation, matching
    assert_includes relation, other
  end

  test 'groups are OR-ed and conditions within a group are AND-ed' do
    both = build_star_system(starport_code: 'A')
    both.update!(known: true)
    only_starport = build_star_system(starport_code: 'A')
    only_starport.update!(known: false)
    only_native = build_star_system(starport_code: 'B')
    only_native.update!(native_sophont: true)
    neither = build_star_system(starport_code: 'B')

    builder = SystemQueryBuilder.new(
      groups: [
        [
          { field: 'starport', operator: 'eq', negate: false, values: ['A'] },
          { field: 'known', operator: 'eq', negate: false, values: ['true'] }
        ],
        [
          { field: 'native_sophont', operator: 'eq', negate: false, values: ['true'] }
        ]
      ]
    )
    relation = builder.relation

    assert_includes relation, both
    assert_not_includes relation, only_starport
    assert_includes relation, only_native
    assert_not_includes relation, neither
  end

  # Cross-check against SurveyOverlay#matches? for the conditions both
  # implementations share, to guard against the two independent evaluators
  # (Ruby vs SQL) drifting apart.
  test 'agrees with SurveyOverlay#matches? on a representative set of conditions' do
    star_system = build_star_system(starport_code: 'B', population_code: 7, tech_level_code: 9)
    star_system.update!(survey_index: 8, native_sophont: true)
    star_system.update!(allegiance: allegiances(:one))
    star_system.primary_star.update!(stellar_class: 'V')

    [
      { field: 'starport', operator: 'gte', values: ['C'] },
      { field: 'population', operator: 'eq', values: ['7'] },
      { field: 'tech_level', operator: 'gt', values: ['5'] },
      { field: 'survey_index', operator: 'between', values: %w[1 10] },
      { field: 'native_sophont', operator: 'eq', values: ['true'] },
      { field: 'allegiance', operator: 'one_of', values: [allegiances(:one).code, allegiances(:two).code] },
      { field: 'primary_star', operator: 'eq', values: ['G'] },
      { field: 'primary_star_class', operator: 'gt', values: ['III'] },
      { field: 'star_count', operator: 'eq', values: ['1'] }
    ].each do |condition|
      overlay = SurveyOverlay.new(
        name: 'Test', colour: '#123456',
        rule_data: { groups: [[condition.merge(negate: false)]] }
      )
      sql_relation = relation_for(field: condition[:field], operator: condition[:operator], values: condition[:values])

      assert_equal overlay.matches?(star_system), sql_relation.exists?(star_system.id),
                   "expected SQL and Ruby evaluators to agree for #{condition.inspect}"
    end
  end
end
