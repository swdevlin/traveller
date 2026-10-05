require 'test_helper'

class SystemQueryTest < ActiveSupport::TestCase
  test 'requires a name' do
    system_query = SystemQuery.new(columns: [])

    assert_not system_query.valid?
    assert system_query.errors[:name].any?
  end

  test 'a rule with no groups is valid' do
    system_query = SystemQuery.new(name: 'Test', rule_data: {}, columns: [])

    assert system_query.valid?
  end

  test 'rejects an unknown field, mirroring SurveyOverlay validation' do
    system_query = SystemQuery.new(
      name: 'Test', columns: [],
      rule_data: { groups: [[{ field: 'not_a_field', operator: 'eq', negate: false, values: ['A'] }]] }
    )

    assert_not system_query.valid?
    assert system_query.errors[:rule_data].any?
  end

  test 'rejects an unknown column key' do
    system_query = SystemQuery.new(name: 'Test', columns: ['not-a-real-column'])

    assert_not system_query.valid?
    assert system_query.errors[:columns].any?
  end

  test 'accepts every known column key' do
    system_query = SystemQuery.new(name: 'Test', columns: SystemQuery::COLUMN_KEYS)

    assert system_query.valid?
  end

  test 'rejects sector_location, name and location as choosable columns since they are mandatory' do
    %w[sector_location name location].each do |key|
      system_query = SystemQuery.new(name: 'Test', columns: [key])

      assert_not system_query.valid?, "expected #{key.inspect} to be rejected as a choosable column"
    end
  end

  test 'display_columns always prefixes the combined sector/location column and name' do
    system_query = SystemQuery.new(name: 'Test', columns: %w[uwp allegiance])

    assert_equal %w[sector_location name uwp allegiance], system_query.display_columns
  end

  test 'jump_route is a SystemQuery-only field, not shared onto SurveyOverlay' do
    assert_includes SystemQuery::FIELDS.map(&:first), 'jump_route'
    assert_not_includes SurveyOverlay::FIELDS.map(&:first), 'jump_route'
    assert_equal 'Jump Route', SystemQuery.field_label('jump_route')
  end

  test 'rejects an unknown jump route id' do
    system_query = SystemQuery.new(
      name: 'Test', columns: [],
      rule_data: { groups: [[{ field: 'jump_route', operator: 'eq', negate: false, values: ['999999'] }]] }
    )

    assert_not system_query.valid?
    assert system_query.errors[:rule_data].any?
  end

  test 'accepts a jump route id that exists' do
    route = JumpRoute.create!(name: 'Spinward Main')
    system_query = SystemQuery.new(
      name: 'Test', columns: [],
      rule_data: { groups: [[{ field: 'jump_route', operator: 'eq', negate: false, values: [route.id.to_s] }]] }
    )

    assert system_query.valid?
  end

  test 'picker_options includes jump routes sourced live from the JumpRoute table' do
    route = JumpRoute.create!(name: 'Spinward Main')

    assert_includes SystemQuery.picker_options.fetch('jump_route'), [route.id.to_s, route.name]
  end

  test 'value_label resolves a jump route id to its name, mirroring sector/subsector' do
    route = JumpRoute.create!(name: 'Spinward Main')

    assert_equal 'Spinward Main', SystemQuery.value_label('jump_route', route.id.to_s)
  end

  test 'value_label falls back to the raw value for an id with no matching row' do
    assert_equal '999999', SystemQuery.value_label('jump_route', '999999')
  end

  test 'matching_star_systems delegates to SystemQueryBuilder' do
    star_system = StarSystem.create!(name: 'Test System', parsec: parsecs(:one))
    system_query = SystemQuery.create!(name: 'Test', columns: [], rule_data: {})

    assert_includes system_query.matching_star_systems, star_system
  end
end
