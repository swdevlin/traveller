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

  test 'destroying a city reduces the major city population by its population' do
    stellar_object = stellar_objects(:planet_near_primary)
    stellar_object.cities.destroy_all
    departing = City.create!(stellar_object: stellar_object, population: 600)
    remaining = City.create!(stellar_object: stellar_object, population: 400)

    departing.destroy!

    assert_equal 400, remaining.reload.population
    stellar_object.reload
    assert_equal 1, stellar_object.population_major_cities
    assert_equal 400, stellar_object.population_major_city_population
  end

  test 'destroying the only city on a stellar object does not error' do
    city = City.create!(stellar_object: stellar_objects(:planet_near_primary), population: 500)

    assert_nothing_raised { city.destroy! }
  end

  test 'saving and destroying cities keeps the major city count and population in step' do
    stellar_object = stellar_objects(:planet_near_primary)
    stellar_object.cities.destroy_all
    a = City.create!(stellar_object: stellar_object, population: 1000)
    City.create!(stellar_object: stellar_object, population: 500)

    stellar_object.reload
    assert_equal 2, stellar_object.population_major_cities
    assert_equal 1500, stellar_object.population_major_city_population

    a.update!(population: 2000)
    assert_equal 2500, stellar_object.reload.population_major_city_population

    stellar_object.cities.destroy_all
    stellar_object.reload
    assert_equal 0, stellar_object.population_major_cities
    assert_nil stellar_object.population_major_city_population
  end

  test 'bulk inserts and deletes also keep the major city totals in step' do
    stellar_object = stellar_objects(:planet_near_primary)
    stellar_object.cities.delete_all
    now = Time.current
    City.insert_all!([
      { stellar_object_id: stellar_object.id, population: 700, created_at: now, updated_at: now },
      { stellar_object_id: stellar_object.id, population: 300, created_at: now, updated_at: now }
    ])

    stellar_object.reload
    assert_equal 2, stellar_object.population_major_cities
    assert_equal 1000, stellar_object.population_major_city_population

    stellar_object.cities.where(population: 700).delete_all

    stellar_object.reload
    assert_equal 1, stellar_object.population_major_cities
    assert_equal 300, stellar_object.population_major_city_population
  end
end
