require 'test_helper'

class PopulateDeepnightCampaignJobTest < ActiveJob::TestCase
  def perform_for_campaign
    campaign = campaigns(:one)
    campaign.update!(campaign_type: 'deepnight_revelation', sector_source: 'deepnight_defaults')

    PopulateDeepnightCampaignJob.new.perform(campaign.id)
  end

  test 'creates only the Incognita Citerior sector' do
    assert_difference('Sector.count', 1) { perform_for_campaign }

    sector = Sector.find_by!(x: -10, y: -2)
    assert_equal(-10, sector.x)
    assert_equal(-2, sector.y)
    assert_equal 'Incognita Citerior', sector.name
    assert_equal 'deepnight', sector.source
  end

  test 'remaining creation preserves existing data and repeated requests are idempotent' do
    perform_for_campaign
    sector = Sector.find_by!(PopulateDeepnightCampaignJob::HOME_SECTOR)
    sector.update!(name: 'Keep this name', referee_notes: 'Keep these notes')
    before = sector.attributes
    clear_enqueued_jobs
    expected = DeepnightDefaults.sectors.count { |data| !Sector.exists?(x: data['X'], y: data['Y']) }

    assert_difference('Sector.count', expected) do
      PopulateDeepnightCampaignJob.new.perform(campaigns(:one).id, remaining: true)
    end
    assert_equal before, sector.reload.attributes
    assert enqueued_jobs.any? { |job| job['job_class'] == 'CreateSubsectorJob' }
    clear_enqueued_jobs

    assert_no_difference('Sector.count') do
      PopulateDeepnightCampaignJob.new.perform(campaigns(:one).id, remaining: true)
    end
    assert_no_enqueued_jobs only: CreateSubsectorJob
  end

  test 'enqueues subsector creation for all sixteen subsectors with populate: true' do
    perform_for_campaign

    create_subsector_jobs = enqueued_jobs.select { |j| j['job_class'] == 'CreateSubsectorJob' }
    assert_equal 16, create_subsector_jobs.length
    assert create_subsector_jobs.all? { |j| j['arguments'].last == true }
  end
end
