# frozen_string_literal: true

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
