class ImportRulebookJob < ApplicationJob
  # Its own queue, worked by a single thread (config/queue.yml) — PDF extraction shells out to a
  # CPU-heavy Python subprocess, and running several concurrently starves the box (each one wants
  # 2-3 cores; the default worker's 3 threads meant up to 3 running at once).
  queue_as :rulebook_imports

  def perform(rulebook_id, path, force: false, cleanup_after: false)
    rulebook = Rulebook.find(rulebook_id)
    result = RulebookImporter.new(rulebook).import!(path, force: force)
    Rails.logger.error("Rulebook import failed for ##{rulebook_id}: #{result.errors.join(', ')}") unless result.success?
  rescue StandardError => e
    Rails.logger.error("Rulebook import job crashed for ##{rulebook_id}: #{e.message}")
    Rulebook.find_by(id: rulebook_id)&.update(status: 'failed', import_error: e.message)
  ensure
    FileUtils.rm_f(path) if cleanup_after
  end
end
