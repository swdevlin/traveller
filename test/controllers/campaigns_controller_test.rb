require 'test_helper'

class CampaignsControllerTest < ActionDispatch::IntegrationTest
  test 'new does not show the background-tasks job-count widget (no campaign exists yet)' do
    sign_in_as users(:one)

    get new_campaign_url

    assert_response :success
    assert_select "[data-controller='job-count']", count: 0
  end

  test 'search_sectors returns matching sectors from Traveller Map' do
    sign_in_as users(:one)
    stub_request(:get, 'https://travellermap.com/api/search?q=Spinward%20Marches')
      .to_return(status: 200, body: {
        'Results' => { 'Items' => [{ 'Sector' => { 'Name' => 'Spinward Marches', 'SectorX' => -4, 'SectorY' => -1 } }] }
      }.to_json)

    get search_sectors_campaigns_url(q: 'Spinward Marches')

    assert_response :success
    assert_select 'button[data-name="Spinward Marches"][data-x="-4"][data-y="1"]'
  end

  test 'search_sectors does not query Traveller Map for a short query' do
    sign_in_as users(:one)

    get search_sectors_campaigns_url(q: 'ab')

    assert_response :success
    assert_not_requested :get, %r{travellermap\.com/api/search}
  end

  test 'create builds the chosen initial sector for a charted_space campaign' do
    sign_in_as users(:one)
    stub_request(:get, 'https://travellermap.com/api/metadata?sx=-4&sy=-1')
      .to_return(status: 200, body: { 'Subsectors' => [] }.to_json)

    post campaigns_url, params: {
      campaign: {
        name: 'My New Campaign',
        slug: "camp-#{SecureRandom.hex(4)}",
        campaign_type: 'charted_space',
        initial_sector_name: 'Spinward Marches',
        starting_sector_x: -4,
        starting_sector_y: 1
      }
    }

    campaign = Campaign.find_by!(name: 'My New Campaign')
    assert_redirected_to sectors_path(campaign_slug: campaign.slug)

    Apartment::Tenant.switch(campaign.schema_name) do
      sector = Sector.find_by(x: -4, y: 1)
      assert sector
      assert_equal 'Spinward Marches', sector.name
    end
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end

  test 'create does not build a sector for a charted_space campaign when None was chosen' do
    sign_in_as users(:one)

    post campaigns_url, params: {
      campaign: {
        name: 'My New Campaign',
        slug: "camp-#{SecureRandom.hex(4)}",
        campaign_type: 'charted_space'
      }
    }

    campaign = Campaign.find_by!(name: 'My New Campaign')
    assert_redirected_to sectors_path(campaign_slug: campaign.slug)

    Apartment::Tenant.switch(campaign.schema_name) do
      assert_equal 0, Sector.count
    end
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end
end
