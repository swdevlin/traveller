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
end
