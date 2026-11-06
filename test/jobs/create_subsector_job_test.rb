require 'test_helper'

class CreateSubsectorJobTest < ActiveJob::TestCase
  def setup
    campaigns(:one).update_column(:schema_name, Apartment::Tenant.current)
    @language = WordGenerator.languages.first.to_s
  end

  def create_sector(language: @language)
    sector = Sector.new(name: 'Namer', abbreviation: 'Nm', x: 40, y: 40, source: 'manual', language: language)
    sector.skip_subsector_creation = true
    sector.save!
    sector
  end

  def create_subsector_named(sector, name)
    CreateSubsectorJob.perform_now(sector.id, 'A', 1, 1, name)
    sector.subsectors.find_by!(x: 1, y: 1)
  end

  test 'a letter name is replaced by a name generated from the sector language' do
    subsector = create_subsector_named(create_sector, 'A')

    assert_predicate subsector.name, :present?
    assert_not_equal 'A', subsector.name
  end

  test 'a name the user entered is kept' do
    subsector = create_subsector_named(create_sector, 'Alpha Reach')

    assert_equal 'Alpha Reach', subsector.name
  end

  test 'a letter name is kept when the sector has no language' do
    campaigns(:one).update_column(:settings, campaigns(:one).settings.merge('default_language' => nil))
    subsector = create_subsector_named(create_sector(language: nil), 'A')

    assert_equal 'A', subsector.name
  end

  test 'a Traveller Map subsector queues its population when asked to' do
    stub_request(:get, %r{travellermap\.com/api/sec\?}).to_return(status: 200, body: file_fixture('t5_tab_subsector.txt').read)
    sector = Sector.new(name: 'Mapped', abbreviation: 'Mp', x: 41, y: 41, source: 'traveller_map')
    sector.skip_subsector_creation = true
    sector.save!(validate: false)

    assert_enqueued_with(job: GenerateSubsectorJob) do
      CreateSubsectorJob.perform_now(sector.id, 'A', 1, 1, 'Mapped A', nil, 'default', true)
    end
  end

  def create_incognita_citerior
    sector = Sector.new(name: 'Incognita Citerior', abbreviation: 'IC', x: -10, y: -2, source: 'deepnight')
    sector.skip_subsector_creation = true
    sector.save!
    sector
  end

  test 'seeds the Revelation ship at Demnan, dated 1105-001, for Incognita Citerior subsector L in a deepnight_revelation campaign' do
    campaigns(:one).update_column(:campaign_type, 'deepnight_revelation')
    sector = create_incognita_citerior

    CreateSubsectorJob.perform_now(sector.id, 'L', 4, 3, 'IC L')

    ship = Ship.find_by!(name: 'Revelation')
    assert_equal 4, ship.jump_drive
    assert_equal 4, ship.m_drive

    jump_log = ship.jump_logs.first
    assert jump_log
    assert_equal jump_log.from_parsec, jump_log.to_parsec
    assert_equal '3124', jump_log.to_parsec.hex_code
    assert_equal 1105, jump_log.depart_year
    assert_equal 1, jump_log.depart_day
    assert_equal 1105, jump_log.arrive_year
    assert_equal 1, jump_log.arrive_day
  end

  test 'does not seed a ship for subsectors other than Demnan\'s' do
    campaigns(:one).update_column(:campaign_type, 'deepnight_revelation')
    sector = create_incognita_citerior

    CreateSubsectorJob.perform_now(sector.id, 'A', 1, 1, 'IC A')

    assert_nil Ship.find_by(name: 'Revelation')
  end

  test 'does not seed a ship for non-deepnight_revelation campaigns' do
    sector = create_incognita_citerior

    CreateSubsectorJob.perform_now(sector.id, 'L', 4, 3, 'IC L')

    assert_nil Ship.find_by(name: 'Revelation')
  end

  test 'does not seed a second ship if one already exists' do
    campaigns(:one).update_column(:campaign_type, 'deepnight_revelation')
    Ship.create!(name: 'Revelation', jump_drive: 4, m_drive: 4)
    sector = create_incognita_citerior

    assert_no_difference -> { Ship.count } do
      CreateSubsectorJob.perform_now(sector.id, 'L', 4, 3, 'IC L')
    end
  end
end
