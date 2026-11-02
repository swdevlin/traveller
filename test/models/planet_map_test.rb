require 'test_helper'

class PlanetMapTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @planet = stellar_objects(:two)
    @planet.update!(size_code: '5', atmosphere_code: 5, hydrographics_code: 5)
  end

  PNG = Base64.decode64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==')

  def upload(content: PNG, type: 'image/png', name: 'world.png')
    file = Tempfile.new(['world', File.extname(name)], binmode: true)
    file.write(content)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, type, true, original_filename: name)
  end

  test 'requires a webp' do
    assert_not PlanetMap.new(stellar_object: @planet, inputs_digest: 'x').valid?
  end

  test 'store_map rasterises the svg and keeps only the webp' do
    @planet.store_map(SAMPLE_SVG)
    map = @planet.reload.planet_map
    data = map.webp_data

    assert_equal 'RIFF', data[0, 4]
    assert_equal 'WEBP', data[8, 4]
    assert_not map.respond_to?(:svg)
    assert_equal 1, ActiveStorage::Attachment.where(record: map).count
  end

  test 'store_map creates then updates a single record' do
    assert_difference('PlanetMap.count', 1) { @planet.store_map(SAMPLE_SVG) }
    assert_no_difference('PlanetMap.count') { @planet.store_map(SAMPLE_SVG) }
  end

  test 'map_stale? is false when freshly stored and true after inputs change' do
    assert_not @planet.map_stale?
    @planet.store_map(SAMPLE_SVG)
    assert_not @planet.map_stale?
    @planet.update!(name: 'Changed Name')
    assert @planet.map_stale?
  end

  test 'map_stale? is true after a city changes' do
    @planet.store_map(SAMPLE_SVG)
    cities(:one).update!(name: 'Renamed')
    assert @planet.reload.map_stale?
  end

  test 'stores the file under the opaque tenant key then the maps directory' do
    @planet.store_map(SAMPLE_SVG)
    webp = @planet.reload.planet_map.webp
    path = webp.service.path_for(webp.key)
    tenant = Apartment::Tenant.current
    campaign = Campaign.find_by(schema_name: tenant)
    folder = campaign ? campaign.storage_key : 'public'

    assert_includes path, "/#{folder}/maps/"
    assert_not_includes path, "/#{tenant}/" unless tenant == 'public'
    assert File.exist?(path)
  end

  test 'regenerating replaces the stored file' do
    @planet.store_map(SAMPLE_SVG)
    old_path = @planet.reload.planet_map.webp.service.path_for(@planet.planet_map.webp.key)

    perform_enqueued_jobs { @planet.store_map(SAMPLE_SVG.sub('red', 'blue')) }

    assert_not File.exist?(old_path)
    assert_equal 'WEBP', @planet.reload.planet_map.webp_data[8, 4]
  end

  test 'a rasterising failure leaves the existing map untouched' do
    @planet.store_map(SAMPLE_SVG)
    key = @planet.reload.planet_map.webp.key

    assert_raises(RuntimeError) { @planet.store_map('not an svg') }
    assert_equal key, @planet.reload.planet_map.webp.key
  end

  test 'map_supported? excludes size 0 and S but includes planetoids of size 1 or greater' do
    planetoid = Planetoid.new(size_code: '1')
    assert planetoid.map_supported?

    %w[0 S].each do |size|
      planetoid.size_code = size
      assert_not planetoid.map_supported?
    end
  end

  test 'store_uploaded_map keeps the image as supplied' do
    assert_nil @planet.store_uploaded_map(upload)
    map = @planet.reload.planet_map

    assert map.uploaded?
    assert_equal 'image/png', map.webp.content_type
    assert_equal PNG, map.webp_data
  end

  test 'an upload replaces a generated map and is never stale' do
    @planet.store_map(SAMPLE_SVG)
    @planet.store_uploaded_map(upload)

    assert_equal 1, PlanetMap.where(stellar_object: @planet).count
    assert @planet.planet_map.uploaded?
    @planet.update!(name: 'Renamed')
    assert_not @planet.reload.map_stale?
  end

  test 'regenerating replaces an upload' do
    @planet.store_uploaded_map(upload)
    @planet.store_map(SAMPLE_SVG)

    assert @planet.reload.planet_map.generated?
    assert_equal 'RIFF', @planet.planet_map.webp_data[0, 4]
  end

  test 'store_uploaded_map rejects unsupported types and keeps the existing map' do
    @planet.store_map(SAMPLE_SVG)
    key = @planet.reload.planet_map.webp.key

    assert_match(/PNG, JPEG, WebP or GIF/, @planet.store_uploaded_map(upload(content: '<svg/>', type: 'image/svg+xml', name: 'x.svg')))
    assert_equal key, @planet.reload.planet_map.webp.key
  end

  test 'store_uploaded_map requires a file' do
    assert_match(/Choose an image/, @planet.store_uploaded_map(nil))
  end

  test 'clear_map removes a generated or uploaded map' do
    @planet.store_map(SAMPLE_SVG)
    assert_difference('PlanetMap.count', -1) { @planet.clear_map }

    @planet.reload.store_uploaded_map(upload)
    assert_difference('PlanetMap.count', -1) { @planet.reload.clear_map }
    assert_nil @planet.reload.planet_map
  end
end
