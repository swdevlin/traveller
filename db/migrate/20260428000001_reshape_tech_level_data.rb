# frozen_string_literal: true

class ReshapeTechLevelData < ActiveRecord::Migration[8.1]
  def up
    StellarObject.where("data ? 'tech_level_code'").find_each do |so|
      code = so.data['tech_level_code']
      next if code.nil?
      so.data['tech_level'] = build_tech_level(code)
      so.data.delete('tech_level_code')
      so.update_column(:data, so.data)
    end
  end

  def down
    StellarObject.where("data ? 'tech_level'").find_each do |so|
      code = so.data.dig('tech_level', 'code')
      so.data['tech_level_code'] = code
      so.data.delete('tech_level')
      so.update_column(:data, so.data)
    end
  end

  private

  def build_tech_level(code)
    {
      'code'              => code,
      'energy'            => code,
      'electronics'       => code,
      'manufacturing'     => code,
      'medical'           => code,
      'environmental'     => code,
      'land'              => code,
      'sea'               => code,
      'air'               => code,
      'space'             => code,
      'personal_military' => code,
      'heavy_military'    => code
    }
  end
end
