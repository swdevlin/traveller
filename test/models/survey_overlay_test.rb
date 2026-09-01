require 'test_helper'

class SurveyOverlayTest < ActiveSupport::TestCase
  test 'requires a name' do
    survey_overlay = SurveyOverlay.new(colour: '#123456')

    assert_not survey_overlay.valid?
    assert survey_overlay.errors[:name].any?
  end

  test 'requires a hex colour' do
    survey_overlay = SurveyOverlay.new(name: 'Test', colour: 'not-a-colour')

    assert_not survey_overlay.valid?
    assert survey_overlay.errors[:colour].any?
  end

  test 'defaults to enabled true' do
    survey_overlay = SurveyOverlay.create!(name: 'Test', colour: '#123456')

    assert survey_overlay.enabled?
  end

  test 'assigns the next position on create' do
    SurveyOverlay.destroy_all
    first = SurveyOverlay.create!(name: 'First', colour: '#123456')
    second = SurveyOverlay.create!(name: 'Second', colour: '#654321')

    assert_equal 1, first.position
    assert_equal 2, second.position
  end

  test 'move_up! swaps position with the previous survey overlay' do
    SurveyOverlay.destroy_all
    first = SurveyOverlay.create!(name: 'First', colour: '#123456')
    second = SurveyOverlay.create!(name: 'Second', colour: '#654321')

    second.move_up!

    assert_equal 2, first.reload.position
    assert_equal 1, second.reload.position
  end

  test 'move_down! swaps position with the next survey overlay' do
    SurveyOverlay.destroy_all
    first = SurveyOverlay.create!(name: 'First', colour: '#123456')
    second = SurveyOverlay.create!(name: 'Second', colour: '#654321')

    first.move_down!

    assert_equal 2, first.reload.position
    assert_equal 1, second.reload.position
  end

  test 'a rule with no groups is valid' do
    survey_overlay = SurveyOverlay.new(name: 'Test', colour: '#123456', rule_data: {})

    assert survey_overlay.valid?
  end

  test 'a rule with well-formed groups and conditions is valid' do
    survey_overlay = SurveyOverlay.new(
      name: 'Test', colour: '#123456',
      rule_data: { groups: [[{ field: 'starport', operator: 'one_of', negate: false, values: %w[A B] }]] }
    )

    assert survey_overlay.valid?
  end

  test 'rejects an unknown field' do
    survey_overlay = SurveyOverlay.new(
      name: 'Test', colour: '#123456',
      rule_data: { groups: [[{ field: 'not_a_field', operator: 'eq', negate: false, values: ['A'] }]] }
    )

    assert_not survey_overlay.valid?
    assert survey_overlay.errors[:rule_data].any?
  end

  test 'rejects an unsupported operator for a boolean field' do
    survey_overlay = SurveyOverlay.new(
      name: 'Test', colour: '#123456',
      rule_data: { groups: [[{ field: 'known', operator: 'gt', negate: false, values: ['true'] }]] }
    )

    assert_not survey_overlay.valid?
    assert survey_overlay.errors[:rule_data].any?
  end

  test 'rejects a between condition without exactly 2 values' do
    survey_overlay = SurveyOverlay.new(
      name: 'Test', colour: '#123456',
      rule_data: { groups: [[{ field: 'population', operator: 'between', negate: false, values: ['1'] }]] }
    )

    assert_not survey_overlay.valid?
    assert survey_overlay.errors[:rule_data].any?
  end

  test 'rejects a condition with no values' do
    survey_overlay = SurveyOverlay.new(
      name: 'Test', colour: '#123456',
      rule_data: { groups: [[{ field: 'starport', operator: 'eq', negate: false, values: [] }]] }
    )

    assert_not survey_overlay.valid?
    assert survey_overlay.errors[:rule_data].any?
  end

  test 'rejects a group that is not an array' do
    survey_overlay = SurveyOverlay.new(name: 'Test', colour: '#123456', rule_data: { groups: 'not-an-array' })

    assert_not survey_overlay.valid?
    assert survey_overlay.errors[:rule_data].any?
  end

  test 'rejects an invalid starport code' do
    survey_overlay = SurveyOverlay.new(
      name: 'Test', colour: '#123456',
      rule_data: { groups: [[{ field: 'starport', operator: 'eq', negate: false, values: ['Z'] }]] }
    )

    assert_not survey_overlay.valid?
    assert survey_overlay.errors[:rule_data].any?
  end

  test 'accepts every valid starport code' do
    SurveyOverlay::FIELD_OPTIONS.fetch('starport').map(&:first).each do |code|
      survey_overlay = SurveyOverlay.new(
        name: 'Test', colour: '#123456',
        rule_data: { groups: [[{ field: 'starport', operator: 'eq', negate: false, values: [code] }]] }
      )

      assert survey_overlay.valid?, "expected starport code #{code.inspect} to be valid"
    end
  end

  test 'rejects an invalid hydrographics code' do
    survey_overlay = SurveyOverlay.new(
      name: 'Test', colour: '#123456',
      rule_data: { groups: [[{ field: 'hydrographics', operator: 'eq', negate: false, values: ['Z'] }]] }
    )

    assert_not survey_overlay.valid?
    assert survey_overlay.errors[:rule_data].any?
  end

  test 'accepts every valid hydrographics code' do
    SurveyOverlay::FIELD_OPTIONS.fetch('hydrographics').map(&:first).each do |code|
      survey_overlay = SurveyOverlay.new(
        name: 'Test', colour: '#123456',
        rule_data: { groups: [[{ field: 'hydrographics', operator: 'eq', negate: false, values: [code] }]] }
      )

      assert survey_overlay.valid?, "expected hydrographics code #{code.inspect} to be valid"
    end
  end

  test 'rejects an unknown base code' do
    survey_overlay = SurveyOverlay.new(
      name: 'Test', colour: '#123456',
      rule_data: { groups: [[{ field: 'bases', operator: 'has', negate: false, values: ['not-a-real-code'] }]] }
    )

    assert_not survey_overlay.valid?
    assert survey_overlay.errors[:rule_data].any?
  end

  test 'accepts a base code that exists in the Facility table' do
    facility = Facility.create!(code: 'ZZ-TEST', name: 'Test Facility')

    survey_overlay = SurveyOverlay.new(
      name: 'Test', colour: '#123456',
      rule_data: { groups: [[{ field: 'bases', operator: 'has', negate: false, values: [facility.code] }]] }
    )

    assert survey_overlay.valid?
  end

  test 'picker_options includes bases sourced live from the Facility table' do
    facility = Facility.create!(code: 'ZZ-TEST2', name: 'Test Facility Two')

    assert_includes SurveyOverlay.picker_options.fetch('bases'), [facility.code, facility.name]
  end

  test 'picker_options includes allegiances sourced live from the Allegiance table' do
    allegiance = allegiances(:one)

    assert_includes SurveyOverlay.picker_options.fetch('allegiance'), [allegiance.code, allegiance.name]
  end

  test 'picker_options includes sectors sourced live from the Sector table' do
    sector = sectors(:one)

    assert_includes SurveyOverlay.picker_options.fetch('sector'), [sector.id.to_s, sector.name]
  end

  test 'picker_options includes subsectors sourced live from the Subsector table, labelled with their sector' do
    subsector = subsectors(:subsector_1_1)

    assert_includes SurveyOverlay.picker_options.fetch('subsector'),
                     [subsector.id.to_s, "#{subsector.name} (#{subsector.sector.name})"]
  end

  test 'rejects an unknown allegiance code' do
    survey_overlay = overlay_with(field: 'allegiance', operator: 'eq', values: ['not-a-real-code'])

    assert_not survey_overlay.valid?
    assert survey_overlay.errors[:rule_data].any?
  end

  test 'accepts an allegiance code that exists in the Allegiance table' do
    survey_overlay = overlay_with(field: 'allegiance', operator: 'eq', values: [allegiances(:one).code])

    assert survey_overlay.valid?
  end

  test 'rejects an unknown sector id' do
    survey_overlay = overlay_with(field: 'sector', operator: 'eq', values: ['999999'])

    assert_not survey_overlay.valid?
    assert survey_overlay.errors[:rule_data].any?
  end

  test 'accepts a sector id that exists' do
    survey_overlay = overlay_with(field: 'sector', operator: 'eq', values: [sectors(:one).id.to_s])

    assert survey_overlay.valid?
  end

  test 'rejects an unknown subsector id' do
    survey_overlay = overlay_with(field: 'subsector', operator: 'eq', values: ['999999'])

    assert_not survey_overlay.valid?
    assert survey_overlay.errors[:rule_data].any?
  end

  test 'accepts a subsector id that exists' do
    survey_overlay = overlay_with(field: 'subsector', operator: 'eq', values: [subsectors(:subsector_1_1).id.to_s])

    assert survey_overlay.valid?
  end

  # matches?/colour_for — mirrors Traveller.HighlightRule.evaluate/matchColour

  FakeStarSystem = Struct.new(
    :main_world_uwp, :survey_index, :known, :gas_giant_count, :belt_count,
    :native_sophont, :extinct_sophont, :main_world_importance, :base_codes,
    :allegiance, :parsec, :primary_star, :stars,
    keyword_init: true
  ) do
    def known?
      known
    end

    def facilities
      base_codes.to_a.map { |code| Struct.new(:code).new(code) }
    end
  end

  FakeAllegiance = Struct.new(:code, keyword_init: true)
  FakeSubsector = Struct.new(:id, keyword_init: true)
  FakeParsec = Struct.new(:sector_id, :subsector, keyword_init: true)
  FakeStar = Struct.new(:stellar_type, :stellar_class, keyword_init: true)

  def fake_star_system(**overrides)
    FakeStarSystem.new(
      {
        main_world_uwp: 'A788899-C', survey_index: 5, known: true, gas_giant_count: 2, belt_count: 1,
        native_sophont: false, extinct_sophont: false, main_world_importance: nil, base_codes: [],
        allegiance: nil, parsec: FakeParsec.new(sector_id: 7, subsector: FakeSubsector.new(id: 3)),
        primary_star: FakeStar.new(stellar_type: 'G', stellar_class: 'V'), stars: [1]
      }.merge(overrides)
    )
  end

  def overlay_with(field:, operator:, values:, negate: false)
    SurveyOverlay.new(
      name: 'Test', colour: '#123456',
      rule_data: { groups: [[{ field: field, operator: operator, negate: negate, values: values }]] }
    )
  end

  test 'matches? eq operator on a UWP field' do
    overlay = overlay_with(field: 'starport', operator: 'eq', values: ['A'])

    assert overlay.matches?(fake_star_system(main_world_uwp: 'A788899-C'))
    assert_not overlay.matches?(fake_star_system(main_world_uwp: 'B788899-C'))
  end

  test 'matches? one_of operator' do
    overlay = overlay_with(field: 'starport', operator: 'one_of', values: %w[A B])

    assert overlay.matches?(fake_star_system(main_world_uwp: 'B788899-C'))
    assert_not overlay.matches?(fake_star_system(main_world_uwp: 'C788899-C'))
  end

  test 'matches? starport rank is reversed so gt C matches A and B but not D, E, X' do
    overlay = overlay_with(field: 'starport', operator: 'gt', values: ['C'])

    assert overlay.matches?(fake_star_system(main_world_uwp: 'A788899-C'))
    assert overlay.matches?(fake_star_system(main_world_uwp: 'B788899-C'))
    assert_not overlay.matches?(fake_star_system(main_world_uwp: 'C788899-C'))
    assert_not overlay.matches?(fake_star_system(main_world_uwp: 'D788899-C'))
    assert_not overlay.matches?(fake_star_system(main_world_uwp: 'X788899-C'))
  end

  test 'matches? lt/lte/gte operators on a non-reversed field' do
    lt = overlay_with(field: 'population', operator: 'lt', values: ['5'])
    gte = overlay_with(field: 'population', operator: 'gte', values: ['5'])

    assert lt.matches?(fake_star_system(main_world_uwp: 'A788499-C'))
    assert_not lt.matches?(fake_star_system(main_world_uwp: 'A788599-C'))
    assert gte.matches?(fake_star_system(main_world_uwp: 'A788599-C'))
    assert_not gte.matches?(fake_star_system(main_world_uwp: 'A788499-C'))
  end

  test 'matches? between operator' do
    overlay = overlay_with(field: 'population', operator: 'between', values: %w[4 6])

    assert overlay.matches?(fake_star_system(main_world_uwp: 'A788599-C'))
    assert_not overlay.matches?(fake_star_system(main_world_uwp: 'A788999-C'))
  end

  test 'matches? negate flips the result' do
    overlay = overlay_with(field: 'starport', operator: 'eq', values: ['A'], negate: true)

    assert_not overlay.matches?(fake_star_system(main_world_uwp: 'A788899-C'))
    assert overlay.matches?(fake_star_system(main_world_uwp: 'B788899-C'))
  end

  test 'matches? bases has and has_one_of operators' do
    has = overlay_with(field: 'bases', operator: 'has', values: ['N'])
    has_one_of = overlay_with(field: 'bases', operator: 'has_one_of', values: %w[N S])

    assert has.matches?(fake_star_system(base_codes: %w[N W]))
    assert_not has.matches?(fake_star_system(base_codes: %w[W]))
    assert has_one_of.matches?(fake_star_system(base_codes: %w[S]))
    assert_not has_one_of.matches?(fake_star_system(base_codes: %w[W]))
  end

  test 'matches? native_sophont and extinct_sophont boolean fields' do
    native = overlay_with(field: 'native_sophont', operator: 'eq', values: ['true'])
    extinct = overlay_with(field: 'extinct_sophont', operator: 'eq', values: ['true'])

    assert native.matches?(fake_star_system(native_sophont: true))
    assert_not native.matches?(fake_star_system(native_sophont: false))
    assert extinct.matches?(fake_star_system(extinct_sophont: true))
    assert_not extinct.matches?(fake_star_system(extinct_sophont: false))
  end

  test 'matches? known and survey_index fields' do
    known = overlay_with(field: 'known', operator: 'eq', values: ['false'])
    survey = overlay_with(field: 'survey_index', operator: 'gte', values: ['10'])

    assert known.matches?(fake_star_system(known: false))
    assert_not known.matches?(fake_star_system(known: true))
    assert survey.matches?(fake_star_system(survey_index: 12))
    assert_not survey.matches?(fake_star_system(survey_index: 5))
  end

  test 'matches? importance condition fails gracefully when the system has no main world importance' do
    overlay = overlay_with(field: 'importance', operator: 'eq', values: ['3'])

    assert_not overlay.matches?(fake_star_system(main_world_importance: nil))
    assert overlay.matches?(fake_star_system(main_world_importance: 3))
  end

  test 'matches? groups are OR-ed and conditions within a group are AND-ed' do
    overlay = SurveyOverlay.new(
      name: 'Test', colour: '#123456',
      rule_data: {
        groups: [
          [
            { field: 'starport', operator: 'eq', negate: false, values: ['A'] },
            { field: 'known', operator: 'eq', negate: false, values: ['true'] }
          ],
          [
            { field: 'native_sophont', operator: 'eq', negate: false, values: ['true'] }
          ]
        ]
      }
    )

    assert overlay.matches?(fake_star_system(main_world_uwp: 'A788899-C', known: true))
    assert_not overlay.matches?(fake_star_system(main_world_uwp: 'A788899-C', known: false))
    assert overlay.matches?(fake_star_system(main_world_uwp: 'B788899-C', native_sophont: true))
    assert_not overlay.matches?(fake_star_system(main_world_uwp: 'B788899-C', native_sophont: false))
  end

  test 'matches? allegiance field compares the code' do
    overlay = overlay_with(field: 'allegiance', operator: 'eq', values: ['Im'])

    assert overlay.matches?(fake_star_system(allegiance: FakeAllegiance.new(code: 'Im')))
    assert_not overlay.matches?(fake_star_system(allegiance: FakeAllegiance.new(code: 'Zh')))
    assert_not overlay.matches?(fake_star_system(allegiance: nil))
  end

  test 'matches? allegiance one_of operator' do
    overlay = overlay_with(field: 'allegiance', operator: 'one_of', values: %w[Im Zh])

    assert overlay.matches?(fake_star_system(allegiance: FakeAllegiance.new(code: 'Zh')))
    assert_not overlay.matches?(fake_star_system(allegiance: FakeAllegiance.new(code: 'So')))
  end

  test 'matches? sector field compares the parsec sector id' do
    overlay = overlay_with(field: 'sector', operator: 'eq', values: ['7'])

    assert overlay.matches?(fake_star_system)
    assert_not overlay.matches?(
      fake_star_system(parsec: FakeParsec.new(sector_id: 8, subsector: FakeSubsector.new(id: 3)))
    )
  end

  test 'matches? subsector field compares the parsec subsector id' do
    overlay = overlay_with(field: 'subsector', operator: 'eq', values: ['3'])

    assert overlay.matches?(fake_star_system)
    assert_not overlay.matches?(fake_star_system(parsec: FakeParsec.new(sector_id: 7, subsector: nil)))
  end

  test 'matches? primary_star compares the primary star stellar_type' do
    overlay = overlay_with(field: 'primary_star', operator: 'one_of', values: %w[G M])

    assert overlay.matches?(fake_star_system(primary_star: FakeStar.new(stellar_type: 'M', stellar_class: 'V')))
    assert_not overlay.matches?(fake_star_system(primary_star: FakeStar.new(stellar_type: 'K', stellar_class: 'V')))
  end

  test 'matches? primary_star_class ranks by luminosity, most to least luminous' do
    overlay = overlay_with(field: 'primary_star_class', operator: 'gt', values: ['III'])

    assert overlay.matches?(fake_star_system(primary_star: FakeStar.new(stellar_type: 'G', stellar_class: 'V')))
    assert_not overlay.matches?(fake_star_system(primary_star: FakeStar.new(stellar_type: 'G', stellar_class: 'III')))
  end

  test 'matches? star_count supports numeric comparisons against the star list length' do
    overlay = overlay_with(field: 'star_count', operator: 'eq', values: ['2'])

    assert overlay.matches?(fake_star_system(stars: [1, 2]))
    assert_not overlay.matches?(fake_star_system(stars: [1]))
  end

  test 'colour_for returns the colour of the first enabled, matching overlay in order' do
    first  = overlay_with(field: 'starport', operator: 'eq', values: ['A'])
    first.colour = '#111111'
    second = overlay_with(field: 'starport', operator: 'eq', values: ['A'])
    second.colour = '#222222'

    system = fake_star_system(main_world_uwp: 'A788899-C')

    assert_equal '#111111', SurveyOverlay.colour_for(system, [first, second])
    assert_equal '#222222', SurveyOverlay.colour_for(system, [second, first])
  end

  test 'colour_for returns nil when no overlay matches' do
    overlay = overlay_with(field: 'starport', operator: 'eq', values: ['A'])

    assert_nil SurveyOverlay.colour_for(fake_star_system(main_world_uwp: 'B788899-C'), [overlay])
  end
end
