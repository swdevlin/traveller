# frozen_string_literal: true

class Primary2Table < RollTable
  def initialize
    table = {
      1 => { id: :unusual_object, description: 'Extremely unusual object' },
      2 => { id: :interstellar_wreck, description: 'Drifting interstellar wreck' },
      3 => { id: :unusual_object, description: 'Dangerous object such as a relic from an ancient war or inhabited cometary body' },
      4 => { id: :unusual_object, description: 'Increased gravity or radiation with no obvious source' },
      5 => { id: :historic_habitation, description: 'Planetoid or cometary body with signs of long-ago habitation' },
      6 => { id: :gas_cloud, description: 'Unusually dense gas cloud' }
    }
    super(table: table, dice: 1, size: 6)
  end
end

class Primary12Table < RollTable
  def initialize(dice: 1, size: 6)
    table = {
      1 => { id: :comet, comet_type: 'large', description: 'Large Cometary Body' },
      2 => { id: :planetoid, description: 'Rogue Dwarf Planet' },
      3 => { id: :planetoid_belt, description: 'Rogue Planetoid Cluster' },
      4 => { id: :terrestrial_planet, description: 'Rogue Planet' },
      5 => { id: :gas_giant, description: 'Rogue Gas Giant' },
      6 => { id: :unusual_object, description: 'Highly unusual large rogue body' }
    }
    super(table: table, dice: 1, size: 6)
  end
end

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
