require 'test_helper'

class JobQueueStatusTest < ActiveSupport::TestCase
  setup do
    SolidQueue::Job.where(class_name: 'GenerateSubsectorJob').delete_all
  end

  def create_job(subsector_id, tenant: Apartment::Tenant.current, finished: false)
    SolidQueue::Job.create!(
      queue_name: 'subsector_creation',
      class_name: 'GenerateSubsectorJob',
      arguments: { job_class: 'GenerateSubsectorJob', arguments: [subsector_id, ''], tenant: tenant },
      finished_at: finished ? Time.current : nil
    )
  end

  test 'pending_subsector_ids includes jobs with a ready execution' do
    create_job(42)

    assert_includes JobQueueStatus.pending_subsector_ids, 42
  end

  test 'pending_subsector_ids ignores other tenants and jobs without executions' do
    create_job(7, tenant: 'someone_else')
    SolidQueue::ReadyExecution.where(job_id: create_job(8).id).delete_all

    assert_empty JobQueueStatus.pending_subsector_ids
  end
end
