# frozen_string_literal: true

class DeleteSectorJob < ApplicationJob
  def perform(sector_id)
    Sector.find(sector_id).delete
  end
end
