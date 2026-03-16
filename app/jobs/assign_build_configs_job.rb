# frozen_string_literal: true

class AssignBuildConfigsJob < ApplicationJob
  queue_as :default

  def perform(sector_source)
    Sector.all.each do |sector|
      sector.subsectors.each do |subsector|
        if sector_source == 'deepnight_defaults'
          subsector.load_deepnight_defaults!
        else
          subsector.load_travellermap_defaults!
        end
        subsector.save!
      end
    end
  end
end
