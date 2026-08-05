require 'test_helper'

class ReconcileStuckRulebookImportsJobTest < ActiveJob::TestCase
  test 'fails a rulebook stuck processing past the timeout' do
    rulebook = rulebooks(:core)
    rulebook.update!(status: 'processing')
    rulebook.update_column(:updated_at, 20.minutes.ago)

    ReconcileStuckRulebookImportsJob.perform_now

    rulebook.reload
    assert rulebook.failed?
    assert_includes rulebook.import_error, 'interrupted'
  end

  test 'leaves a recently started import alone' do
    rulebook = rulebooks(:core)
    rulebook.update!(status: 'processing')
    rulebook.update_column(:updated_at, 5.minutes.ago)

    ReconcileStuckRulebookImportsJob.perform_now

    assert rulebook.reload.processing?
  end

  test 'leaves non-processing rulebooks alone' do
    rulebook = rulebooks(:failed_import)
    original_error = rulebook.import_error
    rulebook.update_column(:updated_at, 20.minutes.ago)

    ReconcileStuckRulebookImportsJob.perform_now

    rulebook.reload
    assert rulebook.failed?
    assert_equal original_error, rulebook.import_error
  end
end
