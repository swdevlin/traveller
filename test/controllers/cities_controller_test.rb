require 'test_helper'

class CitiesControllerTest < AuthenticatedIntegrationTest
  setup do
    @stellar_object = stellar_objects(:two)
    @city = cities(:one)
  end

  test 'should get new' do
    get new_stellar_object_city_url(@stellar_object)
    assert_response :success
  end

  test 'should create city' do
    assert_difference('City.count') do
      post stellar_object_cities_url(@stellar_object), params: {
        city: { name: 'Newtown', population: 42_000, city_type: 'Ar', capital_designation: 'Cw' }
      }
    end

    city = City.last
    assert_equal @stellar_object, city.stellar_object
    assert_equal 'Ar', city.city_type
    assert_equal 'Cw', city.capital_designation
  end

  test 'should not create city with invalid city_type' do
    assert_no_difference('City.count') do
      post stellar_object_cities_url(@stellar_object), params: {
        city: { name: 'Newtown', population: 42_000, city_type: 'Zz' }
      }
    end

    assert_response :unprocessable_entity
  end

  test 'should get edit' do
    get edit_city_url(@city)
    assert_response :success
  end

  test 'should update city' do
    patch city_url(@city), params: { city: { city_type: 'Ub', capital_designation: 'Cn' } }

    @city.reload
    assert_equal 'Ub', @city.city_type
    assert_equal 'Cn', @city.capital_designation
  end

  test 'should destroy city' do
    assert_difference('City.count', -1) do
      delete city_url(@city)
    end
  end
end
