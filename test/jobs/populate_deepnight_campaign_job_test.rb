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

  test 'enqueues subsector creation for all sixteen subsectors with populate: true' do
    perform_for_campaign

    create_subsector_jobs = enqueued_jobs.select { |j| j['job_class'] == 'CreateSubsectorJob' }
    assert_equal 16, create_subsector_jobs.length
    assert create_subsector_jobs.all? { |j| j['arguments'].last == true }
  end
end
