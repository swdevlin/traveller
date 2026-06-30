# frozen_string_literal: true

module StrategicMapData
  extend ActiveSupport::Concern

  private

  def build_strategic_data
    @strategic_by_pos = @systems_by_pos.transform_values do |sys|
      StrategicAnalysis.new(sys)
    end
  end
end
