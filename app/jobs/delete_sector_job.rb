# frozen_string_literal: true

class DeleteSectorJob < ApplicationJob
  def perform(sector)
    sector.destroy
  end
end
