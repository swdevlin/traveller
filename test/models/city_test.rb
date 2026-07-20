require 'test_helper'

class CityTest < ActiveSupport::TestCase
  test 'valid fixture' do
    assert cities(:one).valid?
  end

  test 'requires a population' do
    city = City.new(stellar_object: stellar_objects(:two))
    assert_not city.valid?
    assert_includes city.errors[:population], "can't be blank"
  end

  test 'rejects a negative population' do
    city = City.new(stellar_object: stellar_objects(:two), population: -1)
    assert_not city.valid?
    assert_includes city.errors[:population], 'must be greater than or equal to 0'
  end

  test 'name is optional' do
    assert cities(:unnamed).valid?
  end

  test 'belongs to a stellar object' do
    assert_equal stellar_objects(:two), cities(:one).stellar_object
  end

  test 'city_type is optional' do
    city = City.new(stellar_object: stellar_objects(:two), population: 1000)
    assert city.valid?
  end

  test 'rejects an unknown city_type' do
    city = City.new(stellar_object: stellar_objects(:two), population: 1000, city_type: 'Zz')
    assert_not city.valid?
    assert_includes city.errors[:city_type], 'is not included in the list'
  end

  test 'accepts a known city_type' do
    city = City.new(stellar_object: stellar_objects(:two), population: 1000, city_type: 'Ar')
    assert city.valid?
  end

  test 'capital_designation is optional' do
    city = City.new(stellar_object: stellar_objects(:two), population: 1000)
    assert city.valid?
  end

  test 'rejects an unknown capital_designation' do
    city = City.new(stellar_object: stellar_objects(:two), population: 1000, capital_designation: 'Zz')
    assert_not city.valid?
    assert_includes city.errors[:capital_designation], 'is not included in the list'
  end

  test 'accepts a known capital_designation' do
    city = City.new(stellar_object: stellar_objects(:two), population: 1000, capital_designation: 'Cw')
    assert city.valid?
  end

  test 'type_label falls back to Standard when city_type is blank' do
    assert_equal 'Standard', cities(:one).type_label
  end

  test 'type_label returns the type description when set' do
    city = City.new(city_type: 'Ar')
    assert_equal 'Arcology, sealed city', city.type_label
  end

  test 'capital_label is nil when capital_designation is blank' do
    assert_nil cities(:one).capital_label
  end

  test 'capital_label returns the designation description when set' do
    city = City.new(capital_designation: 'Cw')
    assert_equal 'World capital', city.capital_label
  end

  test 'destroying a city redistributes its population proportionally to remaining cities' do
    stellar_object = stellar_objects(:planet_near_primary)
    departing = City.create!(stellar_object: stellar_object, population: 520000)
    first = City.create!(stellar_object: stellar_object, population: 310000)
    second = City.create!(stellar_object: stellar_object, population: 150000)

    departing.destroy!

    assert_equal 660435, first.reload.population
    assert_equal 319565, second.reload.population
    assert_equal 980000, first.population + second.population
  end

  test 'destroying a city splits population evenly when remaining cities have zero population' do
    stellar_object = stellar_objects(:planet_near_primary)
    departing = City.create!(stellar_object: stellar_object, population: 100)
    a = City.create!(stellar_object: stellar_object, population: 0)
    b = City.create!(stellar_object: stellar_object, population: 0)
    c = City.create!(stellar_object: stellar_object, population: 0)

    departing.destroy!

    assert_equal 33, a.reload.population
    assert_equal 33, b.reload.population
    assert_equal 34, c.reload.population
  end

  test 'destroying the only city on a stellar object does not error' do
    city = City.create!(stellar_object: stellar_objects(:planet_near_primary), population: 500)

    assert_nothing_raised { city.destroy! }
  end
end
