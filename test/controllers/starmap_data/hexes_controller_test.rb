require 'test_helper'

class StarmapData::HexesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @slug = campaigns(:one).slug
    @gas_giant = stellar_objects(:moons_test_gas_giant)
    @parsec = @gas_giant.star_system.parsec
    sign_in_as users(:one)
  end

  test 'serves the system in a hex with its planets cut down to what the map draws' do
    get hex_url(@parsec), as: :json

    assert_response :success
    assert_equal @parsec.id, response.parsed_body['id']
    giant = find_object(response.parsed_body['star_system'], @gas_giant.id)
    assert_not giant.key?('moons')
    assert_not giant.key?('created_at')
    assert_not giant.key?('survey_records_html')
  end

  test 'every value in a lean body is the value in the full API object' do
    get hex_url(@parsec), as: :json
    lean = response.parsed_body['star_system']
    get "/c/#{@slug}/api/parsecs/#{@parsec.id}", as: :json
    full = response.parsed_body['star_system']

    bodies = collect_bodies(lean)
    assert_operator bodies.size, :>, 1
    bodies.each do |body|
      full_body = find_object(full, body['id'])
      lenient = body.except('rings', 'atmosphere', 'hydrographics', 'jump_shadow')
      assert_equal full_body.slice(*lenient.keys), lenient, "#{body['type']} #{body['id']}"
      assert_equal full_body['jump_shadow']&.slice('distance_km').to_json, body['jump_shadow'].to_json, 'jump shadow'
    end
  end

  test 'the API still returns the full object, with its moons' do
    get "/c/#{@slug}/api/parsecs/#{@parsec.id}", as: :json

    giant = find_object(response.parsed_body['star_system'], @gas_giant.id)
    assert_equal 2, giant['moons'].size
    assert giant.key?('created_at')
  end

  test 'a hex with no parsec is a 404' do
    get "/c/#{@slug}/starmap/data/hex?sx=500&sy=500&hx=1&hy=1", as: :json

    assert_response :not_found
  end

  test 'a hex outside its sector is a 404' do
    get "/c/#{@slug}/starmap/data/hex?sx=0&sy=0&hx=33&hy=1", as: :json

    assert_response :not_found
  end

  test 'a request without all four coordinates is a 404' do
    get "/c/#{@slug}/starmap/data/hex?sx=0&sy=0", as: :json

    assert_response :not_found
  end

  private

  def hex_url(parsec)
    sx = parsec.x.div(32)
    sy = -((-parsec.y).div(40))
    "/c/#{@slug}/starmap/data/hex?sx=#{sx}&sy=#{sy}&hx=#{parsec.x - (sx * 32) + 1}&hy=#{(sy * 40) - parsec.y + 1}"
  end

  def find_object(node, id)
    case node
    when Hash then node['id'] == id && node.key?('orbit_type') ? node : node.values.filter_map { |v| find_object(v, id) }.first
    when Array then node.filter_map { |v| find_object(v, id) }.first
    end
  end

  # planets, belts and gas giants in the tree, which have an orbit_type of 10..13
  def collect_bodies(node)
    case node
    when Hash then (node['orbit_type'].to_i.between?(10, 13) ? [node] : []) + node.values.flat_map { |v| collect_bodies(v) }
    when Array then node.flat_map { |v| collect_bodies(v) }
    else []
    end
  end
end
