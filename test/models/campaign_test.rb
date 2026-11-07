require 'test_helper'

class CampaignTest < ActiveSupport::TestCase
  def stub_sector_metadata(x, y, status: 200, body: nil)
    stub_request(:get, "https://travellermap.com/api/metadata?sx=#{x}&sy=#{-y}")
      .to_return(status: status, body: body || { 'Subsectors' => [] }.to_json)
  end

  test 'creating a campaign seeds a CampaignRulebook for every existing rulebook' do
    stub_sector_metadata(10, 10)
    campaign = Campaign.create!(name: 'New Campaign', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one),
                                 initial_sector_name: 'Spinward Marches', starting_sector_x: 10, starting_sector_y: 10)

    Apartment::Tenant.switch(campaign.schema_name) do
      assert_equal Rulebook.count, CampaignRulebook.count

      core = CampaignRulebook.find_by!(rulebook_id: rulebooks(:core).id)
      assert core.enabled?
      assert core.player_searchable?

      adventure = CampaignRulebook.find_by!(rulebook_id: rulebooks(:failed_import).id)
      assert adventure.enabled?
      assert_not adventure.player_searchable?
    end
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end

  test 'creating a charted space campaign seeds the default sophonts' do
    stub_sector_metadata(10, 10)
    campaign = Campaign.create!(name: 'Charted', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one), campaign_type: 'charted_space',
                                 initial_sector_name: 'Spinward Marches', starting_sector_x: 10, starting_sector_y: 10)

    Apartment::Tenant.switch(campaign.schema_name) do
      assert_equal Sophont::DEFAULT_NAMES.sort, Sophont.pluck(:name).sort
    end
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end

  test 'creating a charted space campaign seeds the nobility tags' do
    stub_sector_metadata(10, 10)
    campaign = Campaign.create!(name: 'Charted', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one), campaign_type: 'charted_space',
                                 initial_sector_name: 'Spinward Marches', starting_sector_x: 10, starting_sector_y: 10)

    Apartment::Tenant.switch(campaign.schema_name) do
      assert_equal Tag::NOBILITY.values.sort, Tag.pluck(:name).sort
    end
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end

  test 'creating a homebrew campaign does not seed nobility tags' do
    campaign = Campaign.create!(name: 'Homebrew', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one), campaign_type: 'homebrew')

    Apartment::Tenant.switch(campaign.schema_name) do
      assert_equal 0, Tag.count
    end
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end

  test 'creating a homebrew campaign does not seed sophonts' do
    campaign = Campaign.create!(name: 'Homebrew', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one), campaign_type: 'homebrew')

    Apartment::Tenant.switch(campaign.schema_name) { assert_equal 0, Sophont.count }
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end

  test 'creating a charted space campaign creates the chosen initial sector' do
    stub_sector_metadata(10, 10)
    campaign = Campaign.create!(name: 'Charted', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one), campaign_type: 'charted_space',
                                 initial_sector_name: 'Spinward Marches', starting_sector_x: 10, starting_sector_y: 10)

    Apartment::Tenant.switch(campaign.schema_name) do
      sector = Sector.find_by(x: 10, y: 10)
      assert sector
      assert_equal 'Spinward Marches', sector.name
      assert_equal 'traveller_map', sector.source
    end
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end

  test 'creating a charted space campaign with no initial sector chosen does not create a sector' do
    campaign = Campaign.create!(name: 'Charted', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one), campaign_type: 'charted_space')

    Apartment::Tenant.switch(campaign.schema_name) do
      assert_equal 0, Sector.count
    end
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end

  test 'choosing a preset sector name without coordinates resolves them from Traveller Map' do
    stub_request(:get, 'https://travellermap.com/api/search?q=Spinward%20Marches')
      .to_return(status: 200, body: {
        'Results' => { 'Items' => [{ 'Sector' => { 'Name' => 'Spinward Marches', 'SectorX' => -4, 'SectorY' => -1 } }] }
      }.to_json)
    stub_sector_metadata(-4, 1)
    campaign = Campaign.create!(name: 'Charted', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one), campaign_type: 'charted_space',
                                 initial_sector_name: 'Spinward Marches')

    Apartment::Tenant.switch(campaign.schema_name) do
      sector = Sector.find_by(x: -4, y: 1)
      assert sector
      assert_equal 'Spinward Marches', sector.name
    end
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end

  test 'creating a deepnight_revelation campaign does not seed the Foreven sector' do
    campaign = Campaign.create!(name: 'Deepnight', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one), campaign_type: 'deepnight_revelation')

    Apartment::Tenant.switch(campaign.schema_name) do
      assert_not Sector.exists?(x: -5, y: 1)
    end
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end

  test 'creating a deepnight_revelation campaign defaults the starting sector to Incognita Citerior' do
    campaign = Campaign.create!(name: 'Deepnight', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one), campaign_type: 'deepnight_revelation')

    assert_equal(-10, campaign.starting_sector_x)
    assert_equal(-2, campaign.starting_sector_y)
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end

  test 'creating a deepnight_revelation campaign defaults sophont_check to the rare earth universe variant' do
    campaign = Campaign.create!(name: 'Deepnight', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one), campaign_type: 'deepnight_revelation')

    assert_equal 'rareEarth', campaign.sophont_check
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end

  test 'creating a charted_space campaign still defaults sophont_check to none' do
    stub_sector_metadata(10, 10)
    campaign = Campaign.create!(name: 'Charted', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one), campaign_type: 'charted_space',
                                 initial_sector_name: 'Spinward Marches', starting_sector_x: 10, starting_sector_y: 10)

    assert_equal 'none', campaign.sophont_check
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end

  test 'creating a homebrew campaign still defaults sophont_check to standard' do
    campaign = Campaign.create!(name: 'Homebrew', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one), campaign_type: 'homebrew')

    assert_equal 'standard', campaign.sophont_check
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end

  test 'creating a campaign with no existing rulebooks does not error' do
    Rulebook.delete_all
    stub_sector_metadata(10, 10)
    campaign = Campaign.create!(name: 'Empty Books Campaign', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one),
                                 initial_sector_name: 'Spinward Marches', starting_sector_x: 10, starting_sector_y: 10)

    Apartment::Tenant.switch(campaign.schema_name) do
      assert_equal 0, CampaignRulebook.count
    end
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end

  # sector_capital_colour / subsector_capital_colour

  test 'capital colours accept a valid hex colour' do
    campaign = campaigns(:one)
    campaign.sector_capital_colour = '#ff0000'
    campaign.subsector_capital_colour = '#00ff00'

    assert campaign.valid?
  end

  test 'capital colours allow blank' do
    campaign = campaigns(:one)
    campaign.sector_capital_colour = ''
    campaign.subsector_capital_colour = nil

    assert campaign.valid?
  end

  test 'capital colours reject a non-hex value' do
    campaign = campaigns(:one)
    campaign.sector_capital_colour = 'red'

    assert_not campaign.valid?
    assert_includes campaign.errors[:sector_capital_colour], 'must be a hex colour (#rrggbb)'
  end

  # hex_size

  test 'hex_size defaults to medium on create' do
    stub_sector_metadata(10, 10)
    campaign = Campaign.create!(name: 'New Campaign', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one),
                                 initial_sector_name: 'Spinward Marches', starting_sector_x: 10, starting_sector_y: 10)

    assert_equal 'medium', campaign.hex_size
    assert_equal 40, campaign.hex_size_value
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end

  test 'hex_size_value maps each size to its pixel value' do
    campaign = campaigns(:one)

    campaign.hex_size = 'small'
    assert_equal 30, campaign.hex_size_value

    campaign.hex_size = 'medium'
    assert_equal 40, campaign.hex_size_value

    campaign.hex_size = 'large'
    assert_equal 50, campaign.hex_size_value
  end

  test 'hex_size allows blank and falls back to medium' do
    campaign = campaigns(:one)
    campaign.hex_size = nil

    assert campaign.valid?
    assert_equal 40, campaign.hex_size_value
  end

  test 'hex_size rejects an unrecognised value' do
    campaign = campaigns(:one)
    campaign.hex_size = 'huge'

    assert_not campaign.valid?
    assert_includes campaign.errors[:hex_size], 'is not included in the list'
  end

  # sector_source

  test 'charted_space campaigns default sector_source to traveller_map on create' do
    stub_sector_metadata(10, 10)
    campaign = Campaign.create!(name: 'New Campaign', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one), campaign_type: 'charted_space',
                                 initial_sector_name: 'Spinward Marches', starting_sector_x: 10, starting_sector_y: 10)

    assert_equal 'traveller_map', campaign.sector_source
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end

  test 'charted_space campaigns with a blank sector_source pick it up on the next save' do
    campaign = campaigns(:one)
    campaign.campaign_type = 'charted_space'
    campaign.sector_source = nil

    campaign.save!

    assert_equal 'traveller_map', campaign.sector_source
  end

  test 'sector_source is left untouched for homebrew campaigns' do
    campaign = campaigns(:one)
    campaign.campaign_type = 'homebrew'
    campaign.sector_source = nil

    campaign.save!

    assert_nil campaign.sector_source
  end

  test 'deepnight_revelation campaigns default sector_source to deepnight_defaults on create' do
    campaign = Campaign.create!(name: 'Deepnight', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one), campaign_type: 'deepnight_revelation')

    assert_equal 'deepnight_defaults', campaign.sector_source
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end

  test 'deepnight_revelation campaigns with a blank sector_source pick it up on the next save' do
    campaign = campaigns(:one)
    campaign.campaign_type = 'deepnight_revelation'
    campaign.sector_source = nil

    campaign.save!

    assert_equal 'deepnight_defaults', campaign.sector_source
  end

  test 'sector_source is not overwritten once set' do
    campaign = campaigns(:one)
    campaign.campaign_type = 'charted_space'
    campaign.sector_source = 'deepnight_defaults'

    campaign.save!

    assert_equal 'deepnight_defaults', campaign.sector_source
  end

  # limited_main_world_eccentricity

  test 'limited_main_world_eccentricity? defaults to false for charted_space campaigns' do
    campaign = campaigns(:one)
    campaign.campaign_type = 'charted_space'
    campaign.limited_main_world_eccentricity = nil

    assert_not campaign.limited_main_world_eccentricity?
  end

  test 'limited_main_world_eccentricity? defaults to false for homebrew campaigns' do
    campaign = campaigns(:one)
    campaign.campaign_type = 'homebrew'
    campaign.limited_main_world_eccentricity = nil

    assert_not campaign.limited_main_world_eccentricity?
  end

  test 'limited_main_world_eccentricity? defaults to false for deepnight_revelation campaigns' do
    campaign = campaigns(:one)
    campaign.campaign_type = 'deepnight_revelation'
    campaign.limited_main_world_eccentricity = nil

    assert_not campaign.limited_main_world_eccentricity?
  end

  test 'limited_main_world_eccentricity? returns the stored value once explicitly set' do
    campaign = campaigns(:one)
    campaign.campaign_type = 'charted_space'
    campaign.limited_main_world_eccentricity = true

    assert campaign.limited_main_world_eccentricity?
  end

  # starting_sector_x / starting_sector_y / starting_sector / starting_location

  test 'starting_sector_x and starting_sector_y allow blank' do
    campaign = campaigns(:one)
    campaign.starting_sector_x = ''
    campaign.starting_sector_y = nil

    assert campaign.valid?
  end

  test 'starting_sector_x and starting_sector_y reject non-integer values' do
    campaign = campaigns(:one)
    campaign.starting_sector_x = 'abc'

    assert_not campaign.valid?
    assert_includes campaign.errors[:starting_sector_x], 'is not a number'
  end

  test 'starting_sector returns the explicitly configured sector' do
    campaign = campaigns(:one)
    sector = sectors(:one)
    campaign.starting_sector_x = sector.x
    campaign.starting_sector_y = sector.y

    assert_equal sector, campaign.starting_sector
  end

  test 'starting_sector falls back to the sector nearest the origin when unset' do
    campaign = campaigns(:one)
    campaign.starting_sector_x = nil
    campaign.starting_sector_y = nil

    assert_equal Sector.nearest_to_origin, campaign.starting_sector
  end

  test 'starting_sector falls back to the sector nearest the origin when the configured sector does not exist' do
    campaign = campaigns(:one)
    campaign.starting_sector_x = 9999
    campaign.starting_sector_y = 9999

    assert_equal Sector.nearest_to_origin, campaign.starting_sector
  end

  test 'starting_location returns the centre of the starting sector' do
    campaign = campaigns(:one)
    sector = sectors(:one)
    campaign.starting_sector_x = sector.x
    campaign.starting_sector_y = sector.y

    centre = sector.centre_coordinate
    assert_equal [centre.x, centre.y], campaign.starting_location
  end

  test 'starting_location falls back to universal (0, 0) when the campaign has no sectors' do
    Sector.delete_all
    campaign = campaigns(:one)

    assert_equal [0, 0], campaign.starting_location
  end

  PNG = Base64.decode64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==')

  test 'destroying a campaign removes its uploaded files and drops its tenant schema' do
    campaign = Campaign.create!(name: 'Homebrew', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one), campaign_type: 'homebrew')
    storage_dir = Rails.root.join('tmp/storage', campaign.storage_key)

    Apartment::Tenant.switch(campaign.schema_name) do
      sophont = Sophont.create!(name: 'Teardown Test')
      sophont.picture.attach(io: StringIO.new(PNG), filename: 'test.png', content_type: 'image/png')
    end

    assert storage_dir.exist?
    assert schema_exists?(campaign.schema_name)

    campaign.destroy

    assert_not storage_dir.exist?
    assert_not schema_exists?(campaign.schema_name)
  end

  private

  def schema_exists?(schema_name)
    quoted = ActiveRecord::Base.connection.quote(schema_name)
    ActiveRecord::Base.connection.select_value("SELECT 1 FROM information_schema.schemata WHERE schema_name = #{quoted}").present?
  end
end
