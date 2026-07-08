# frozen_string_literal: true

class RogueObjectsTable < RollTable
  def initialize
    table = {
      2 => ->(roller:, **_) { Primary2Table.new.roll(roller:) },
      3..4 => { id: :sensor_glitch, description: 'Sensor glitch; nothing present' },
      5..9 => { id: :comet, comet_type: 'tiny', description: 'Tiny ice-bearing comet suitable for one refuelling only' },
      10..11 => { id: :comet, comet_type: 'medium', description: 'Ice-bearing comet suitable for multiple refuelings' },
      12 => ->(roller:, **_) { Primary12Table.new.roll(roller:) }
    }
    super(table: table, dice: 2, size: 6)
  end
end
