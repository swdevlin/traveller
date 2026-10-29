require 'test_helper'

class SophontsControllerTest < AuthenticatedIntegrationTest
  setup do
    @sophont = Sophont.create!(name: 'Vargr', referee_notes: 'Secret', player_notes: 'Canine')
  end

  test 'index lists sophonts' do
    get sophonts_url
    assert_response :success
    assert_match 'Vargr', response.body
  end

  test 'index is paginated' do
    30.times { |i| Sophont.create!(name: "Species #{format('%02d', i)}") }
    get sophonts_url
    assert_response :success
    assert_select 'tbody tr', 10
    get sophonts_url(page: 4)
    assert_select 'tbody tr', 1
  end

  test 'create adds a sophont' do
    assert_difference 'Sophont.count' do
      post sophonts_url, params: { sophont: { name: 'Aslan', language: 'aslan' } }
    end
    assert_redirected_to sophont_url(Sophont.find_by_name('Aslan'))
  end

  test 'create rejects a blank name' do
    assert_no_difference 'Sophont.count' do
      post sophonts_url, params: { sophont: { name: '' } }
    end
    assert_response :unprocessable_entity
  end

  test 'show displays the notes' do
    get sophont_url(@sophont)
    assert_response :success
    assert_match 'Canine', response.body
  end

  test 'show links the home system by name and the sector by its own name' do
    system = StarSystem.joins(:parsec).first
    system.update_columns(name: 'Regina')
    @sophont.update!(home_system: system)

    get sophont_url(@sophont)
    assert_response :success
    assert_select "a[href='#{star_system_path(system)}']", text: 'Regina'
    assert_select "a[href='#{sector_path(system.parsec.sector)}']", text: system.parsec.sector.name
  end

  test 'update changes the sophont' do
    patch sophont_url(@sophont), params: { sophont: { player_notes: 'Updated' } }
    assert_redirected_to sophont_url(@sophont)
    assert_equal 'Updated', @sophont.reload.player_notes
  end

  test 'destroy removes an unused sophont' do
    assert_difference 'Sophont.count', -1 do
      delete sophont_url(@sophont)
    end
  end

  test 'destroy refuses a sophont still in use' do
    stellar_objects(:two).update!(size_code: '5', atmosphere_code: 5, hydrographics_code: 5, sophont_id: @sophont.id)
    assert_no_difference 'Sophont.count' do
      delete sophont_url(@sophont)
    end
    assert_redirected_to sophonts_url
  end

  PNG = Base64.decode64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==')

  def attach_picture
    @sophont.picture.attach(io: StringIO.new(PNG), filename: 'sagani.png', content_type: 'image/png')
  end

  test 'picture is served to a logged-out visitor with a valid token' do
    attach_picture
    path = picture_sophont_path(@sophont)
    token = campaigns(:one).token_for(path)
    sign_out

    get path, params: { token: token }

    assert_response :success
    assert_equal 'image/png', response.media_type
  end

  test 'picture is forbidden to a logged-out visitor without a valid token' do
    attach_picture
    sign_out

    get picture_sophont_path(@sophont), params: { token: 'wrong' }

    assert_response :forbidden
  end

  test 'a token does not unlock other sophont pages for a logged-out visitor' do
    token = campaigns(:one).token_for(sophont_path(@sophont))
    sign_out

    get sophont_path(@sophont), params: { token: token }

    assert_response :redirect
  end

  test 'picture is not found when none attached' do
    get picture_sophont_url(@sophont)
    assert_response :not_found
  end

  test 'editing a world can name a new extinct sophont' do
    planet = stellar_objects(:two)
    patch stellar_object_url(planet), params: {
      stellar_object: { extinct_sophont: 'true', new_extinct_sophont_name: 'Ancients', size_code: '5', atmosphere_code: 5, hydrographics_code: 5 }
    }
    assert_redirected_to stellar_object_url(planet)
    assert_equal 'Ancients', planet.reload.extinct_sophont_record&.name

    get stellar_object_url(planet)
    assert_response :success
    assert_match 'Ancients', response.body
  end

  test 'editing a world can name a new sophont' do
    planet = stellar_objects(:two)
    patch stellar_object_url(planet), params: {
      stellar_object: { native_sophont: 'true', new_sophont_name: 'Droyne', size_code: '5', atmosphere_code: 5, hydrographics_code: 5 }
    }
    assert_redirected_to stellar_object_url(planet)
    assert_equal 'Droyne', planet.reload.sophont&.name

    get stellar_object_url(planet)
    assert_response :success
    assert_match 'Droyne', response.body
  end
end
