# frozen_string_literal: true

module HexMapRogueObjects
  extend ActiveSupport::Concern

  private

  def build_rogue_objects_data(parsec_scope)
    @rogue_object_positions = Set.new
    @rogue_object_icon = nil
    return if @parsecs_by_pos.blank?

    scope = StellarObject
      .where(parsec_id: parsec_scope, orbiting_id: nil)
      .where.not(type: %w[GasGiant Comet Star])

    unless authenticated?
      scope = scope
        .joins(:parsec)
        .where('stellar_objects.known = true OR parsecs.survey_index = 12')
    end

    rogue_parsec_ids = scope.distinct.pluck(:parsec_id)
    return if rogue_parsec_ids.empty?

    parsec_id_to_pos = @parsecs_by_pos.each_with_object({}) { |(pos, data), h| h[data[:id]] = pos }
    rogue_parsec_ids.each { |pid| pos = parsec_id_to_pos[pid]; @rogue_object_positions << pos if pos }

    @rogue_object_icon = FontAwesomeIcon.find_by(name: 'fa-rogue-object', style: 'solid')
  end
end
