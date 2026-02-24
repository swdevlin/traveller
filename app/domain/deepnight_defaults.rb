# frozen_string_literal: true

class DeepnightDefaults
  def self.available?(sector)
    path = Rails.root.join('db', 'data', 'sector_defaults', "#{sector.x}_#{sector.y}.yaml")
    File.exist?(path)
  end
end
