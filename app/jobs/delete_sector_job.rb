# frozen_string_literal: true

class DeleteSectorJob < ApplicationJob
  include TenantAware

  def perform(sector_id)
    Sector.find(sector_id).delete
  end
end
