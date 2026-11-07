require 'test_helper'

class CreateInitialSectorJobTest < ActiveJob::TestCase
  def stub_sector_metadata(x, y, status: 200, body: nil)
    stub_request(:get, "https://travellermap.com/api/metadata?sx=#{x}&sy=#{-y}")
      .to_return(status: status, body: body || { 'Subsectors' => [] }.to_json)
  end

  test 'creates the sector and broadcasts ready when coordinates are already known' do
    stub_sector_metadata(-4, 1)
    campaign = Campaign.create!(name: 'Charted', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one), campaign_type: 'charted_space',
                                 initial_sector_name: 'Spinward Marches', starting_sector_x: -4, starting_sector_y: 1)

    assert_broadcast_on(CampaignProvisioningChannel.broadcasting_for(campaign), event: 'ready') do
      CreateInitialSectorJob.perform_now(campaign.id)
    end

    Apartment::Tenant.switch(campaign.schema_name) do
      sector = Sector.find_by(x: -4, y: 1)
      assert sector
      assert_equal 'Spinward Marches', sector.name
    end
    assert Campaign.exists?(campaign.id)
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end

  test 'resolves coordinates from a Traveller Map search when not pre-filled' do
    stub_request(:get, 'https://travellermap.com/api/search?q=Spinward%20Marches')
      .to_return(status: 200, body: {
        'Results' => { 'Items' => [{ 'Sector' => { 'Name' => 'Spinward Marches', 'SectorX' => -4, 'SectorY' => -1 } }] }
      }.to_json)
    stub_sector_metadata(-4, 1)
    campaign = Campaign.create!(name: 'Charted', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one), campaign_type: 'charted_space',
                                 initial_sector_name: 'Spinward Marches')

    CreateInitialSectorJob.perform_now(campaign.id)

    Apartment::Tenant.switch(campaign.schema_name) do
      assert Sector.find_by(x: -4, y: 1)
    end
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end

  test 'destroys the campaign and broadcasts a message when the sector name cannot be found' do
    stub_request(:get, 'https://travellermap.com/api/search?q=Nonexistent%20Sector')
      .to_return(status: 200, body: { 'Results' => { 'Items' => [] } }.to_json)
    campaign = Campaign.create!(name: 'Charted', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one), campaign_type: 'charted_space',
                                 initial_sector_name: 'Nonexistent Sector')
    schema_name = campaign.schema_name
    campaign_id = campaign.id

    assert_broadcast_on(CampaignProvisioningChannel.broadcasting_for(campaign),
                        event: 'failed', message: 'Could not find “Nonexistent Sector” on Traveller Map.') do
      CreateInitialSectorJob.perform_now(campaign_id)
    end

    assert_not Campaign.exists?(campaign_id)
  ensure
    Apartment::Tenant.drop(schema_name) rescue nil
  end

  test 'surfaces the friendly Traveller Map unreachable message and destroys the campaign' do
    stub_request(:get, 'https://travellermap.com/api/metadata?sx=-4&sy=-1').to_timeout
    campaign = Campaign.create!(name: 'Charted', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one), campaign_type: 'charted_space',
                                 initial_sector_name: 'Spinward Marches', starting_sector_x: -4, starting_sector_y: 1)
    schema_name = campaign.schema_name
    campaign_id = campaign.id

    assert_broadcast_on(CampaignProvisioningChannel.broadcasting_for(campaign),
                        event: 'failed', message: 'Traveller Map is currently unreachable. Please try again later.') do
      CreateInitialSectorJob.perform_now(campaign_id)
    end

    assert_not Campaign.exists?(campaign_id)
  ensure
    Apartment::Tenant.drop(schema_name) rescue nil
  end

  test 'is a no-op when the campaign is already gone' do
    assert_nothing_raised do
      CreateInitialSectorJob.perform_now(-1)
    end
  end
end
