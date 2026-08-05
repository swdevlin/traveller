class ReconcileStuckRulebookImportsJob < ApplicationJob
  queue_as :default

  # A worker process can die mid-import (e.g. a Puma restart in development, or a crash/deploy
  # in production) without ever running ImportRulebookJob's rescue/ensure blocks, leaving the
  # rulebook stuck at status 'processing' forever with no error shown. This sweeps those up.
  STUCK_AFTER = 15.minutes

  def perform
    Rulebook.processing.where(updated_at: ..STUCK_AFTER.ago).find_each do |rulebook|
      rulebook.update!(status: 'failed',
                        import_error: 'Import was interrupted (the worker process died) and never completed. Please retry the upload.')
    end
  end
end
