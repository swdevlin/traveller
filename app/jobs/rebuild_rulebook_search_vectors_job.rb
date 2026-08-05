class RebuildRulebookSearchVectorsJob < ApplicationJob
  queue_as :default

  def perform(rulebook_id)
    RulebookReindexer.new(Rulebook.find(rulebook_id)).call
  rescue StandardError => e
    Rails.logger.error("Rebuild search vectors failed for rulebook ##{rulebook_id}: #{e.message}")
  end
end
