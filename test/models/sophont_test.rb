require 'test_helper'

class SophontTest < ActiveSupport::TestCase
  WORLD = { size_code: '5', atmosphere_code: 5, hydrographics_code: 5 }.freeze

  test 'requires a name' do
    assert_not Sophont.new.valid?
  end

  test 'name is unique ignoring case' do
    Sophont.create!(name: 'Vargr')
    assert_not Sophont.new(name: 'vargr').valid?
  end

  test 'rejects an unknown language' do
    assert_not Sophont.new(name: 'Zhodani', language: 'klingon').valid?
    assert Sophont.new(name: 'Zhodani', language: 'aslan').valid?
  end

  test 'reference link must be a web address' do
    assert Sophont.new(name: 'Zhodani', reference_url: 'https://wiki.travellerrpg.com/Zhodani').valid?
    assert_not Sophont.new(name: 'Zhodani', reference_url: 'javascript:alert(1)').valid?
    assert_not Sophont.new(name: 'Zhodani', reference_url: 'not a url').valid?
  end

  test 'charted space campaigns default the reference link to the Traveller wiki' do
    charted = Campaign.new(campaign_type: 'charted_space')
    homebrew = Campaign.new(campaign_type: 'homebrew')
    sophont = Sophont.new(name: 'Vargr Corsair')
    assert_equal 'https://wiki.travellerrpg.com/Vargr_Corsair', sophont.effective_reference_url(charted)
    assert_nil sophont.effective_reference_url(homebrew)
    sophont.reference_url = 'https://example.com/v'
    assert_equal 'https://example.com/v', sophont.effective_reference_url(charted)
  end

  test 'seed_defaults adds the missing defaults once and keeps existing ones' do
    Sophont.create!(name: 'aslan', referee_notes: 'mine')
    2.times { Sophont.seed_defaults }
    assert_equal Sophont::DEFAULT_NAMES.size, Sophont.count
    assert_equal 'mine', Sophont.find_by_name('Aslan').referee_notes
    assert_equal 'arrghoun', Sophont.find_by_name('Vargr').language
  end

  test 'blank optional fields are stored as nil' do
    sophont = Sophont.create!(name: 'Aslan', language: '', referee_notes: '', player_notes: ' ')
    assert_nil sophont.language
    assert_nil sophont.referee_notes
  end

  test 'a world with a new sophont name creates the sophont with its system as home' do
    planet = stellar_objects(:two)
    planet.update!(**WORLD, parsec: nil, orbiting: stars(:star_one), native_sophont: true, new_sophont_name: 'Droyne')

    sophont = Sophont.find_by_name('droyne')
    assert_not_nil sophont
    assert_not_nil planet.star_system_id
    assert_equal planet.star_system_id, sophont.home_system_id
    assert_equal sophont, planet.reload.sophont
  end

  test 'a new sophont name matching an existing one reuses it' do
    existing = Sophont.create!(name: 'Droyne')
    planet = stellar_objects(:two)

    assert_no_difference 'Sophont.count' do
      planet.update!(**WORLD, new_sophont_name: ' droyne ')
    end
    assert_equal existing, planet.reload.sophont
  end

  test 'a sophont id submitted as a string is stored as an integer' do
    sophont = Sophont.create!(name: 'Sagani')
    planet = stellar_objects(:two)
    planet.update!(**WORLD, sophont_id: sophont.id.to_s)

    assert_equal sophont.id, planet.reload.data['sophont_id']
    assert_includes sophont.worlds, planet
  end

  test 'a world with a new extinct sophont name creates the sophont with its system as home' do
    planet = stellar_objects(:two)
    planet.update!(**WORLD, parsec: nil, orbiting: stars(:star_one), extinct_sophont: true, new_extinct_sophont_name: 'Ancients')

    sophont = Sophont.find_by_name('ancients')
    assert_not_nil sophont
    assert_equal planet.star_system_id, sophont.home_system_id
    assert_equal sophont, planet.reload.extinct_sophont_record
    assert_nil planet.sophont
  end

  test 'an extinct sophont is optional and ignored when the world is not flagged extinct' do
    sophont = Sophont.create!(name: 'Ancients')
    planet = stellar_objects(:two)

    planet.update!(**WORLD, extinct_sophont: true)
    assert_nil planet.reload.extinct_sophont_record

    planet.update!(**WORLD, extinct_sophont: false, extinct_sophont_id: sophont.id.to_s)
    assert_equal sophont.id, planet.reload.data['extinct_sophont_id']
    assert_nil planet.extinct_sophont_record
  end

  test 'a world can have different native and extinct sophonts' do
    native = Sophont.create!(name: 'Vilani')
    extinct = Sophont.create!(name: 'Ancients')
    planet = stellar_objects(:two)
    planet.update!(**WORLD, native_sophont: true, sophont_id: native.id, extinct_sophont: true, extinct_sophont_id: extinct.id)

    assert_equal native, planet.reload.sophont
    assert_equal extinct, planet.extinct_sophont_record
    assert_includes extinct.extinct_worlds, planet
    assert_not_includes native.extinct_worlds, planet
  end

  test 'in_use? is true for an extinct sophont reference' do
    sophont = Sophont.create!(name: 'Ancients')
    assert_not sophont.in_use?
    stellar_objects(:two).update!(**WORLD, extinct_sophont: true, extinct_sophont_id: sophont.id)
    assert sophont.in_use?
  end

  test 'in_use? reflects worlds referencing the sophont' do
    sophont = Sophont.create!(name: 'Hiver')
    assert_not sophont.in_use?
    stellar_objects(:two).update!(**WORLD, sophont_id: sophont.id)
    assert sophont.in_use?
  end
end
