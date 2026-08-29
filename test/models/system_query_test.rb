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

  test 'matching_star_systems delegates to SystemQueryBuilder' do
    star_system = StarSystem.create!(name: 'Test System', parsec: parsecs(:one))
    system_query = SystemQuery.create!(name: 'Test', columns: [], rule_data: {})

    assert_includes system_query.matching_star_systems, star_system
  end
end
