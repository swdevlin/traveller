require 'test_helper'

class GeneratePlanetMapJobTest < ActiveJob::TestCase
  SAMPLE_SVG = '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="200"><rect width="50" height="50" fill="red"/></svg>'.freeze

  setup do
    @planet = stellar_objects(:planet_near_primary)
    @planet.update!(size_code: '5', atmosphere_code: 5, hydrographics_code: 5, orbit: 3.0)
    campaigns(:one).update_column(:schema_name, Apartment::Tenant.current)
    @url = "#{Rails.application.config.x.map_service}/map"
  end

  test 'enqueue uses a priority between 100 and 200' do
    10.times do
      GeneratePlanetMapJob.enqueue(@planet, base_url: 'http://example.com')
    end

    priorities = enqueued_jobs.map { it['priority'] }
    assert_equal 10, priorities.size
    assert(priorities.all? { (100..200).cover?(it) })
  end

  test 'stores a map for a planet without one' do
    stub = stub_request(:post, @url).to_return(status: 200, body: SAMPLE_SVG)

    assert_difference('PlanetMap.count', 1) do
      GeneratePlanetMapJob.perform_now(@planet.id, 'http://example.com')
    end
    assert_requested stub
  end

  test 'does not replace an existing map' do
    @planet.store_map(SAMPLE_SVG)
    stub = stub_request(:post, @url).to_return(status: 200, body: SAMPLE_SVG)

    assert_no_difference('PlanetMap.count') do
      GeneratePlanetMapJob.perform_now(@planet.id, 'http://example.com')
    end
    assert_not_requested stub
  end

  test 'skips bodies too small to map' do
    @planet.update!(size_code: 'S')
    stub = stub_request(:post, @url).to_return(status: 200, body: SAMPLE_SVG)

    GeneratePlanetMapJob.perform_now(@planet.id, 'http://example.com')

    assert_not_requested stub
  end

  test 'ignores a body that no longer exists' do
    assert_nothing_raised { GeneratePlanetMapJob.perform_now(0, 'http://example.com') }
  end
end
