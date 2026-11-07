# frozen_string_literal: true

class DeepnightDefaults
  def self.sectors
    Dir[Rails.root.join('db', 'data', 'sector_defaults', '*.yaml')].sort.map do |path|
      YAML.safe_load_file(path)
    end
  end

  def self.available?(sector)
    path = Rails.root.join('db', 'data', 'sector_defaults', "#{sector.x}_#{sector.y}.yaml")
    File.exist?(path)
  end
end
