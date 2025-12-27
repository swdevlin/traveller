# frozen_string_literal: true

class Primary2Table < RollTable
  def initialize
    table = {
      1 => 'Extremely unusual object',
      2 => 'Drifting interstellar wreck',
      3 => 'Dangerous object such as a relic from an ancient war or inhabited cometary body',
      4 => 'Increased gravity or radiation with no obvious source',
      5 => 'Planetoid or cometary body with signs of long-ago habitation',
      6 => 'Unusually dense gas cloud'
    }
    super(table: table, dice: 1, size: 6)
  end
end

class Primary12Table < RollTable
  def initialize(dice: 1, size: 6)
    table = {
      1 => 'Large Cometary Body',
      2 => 'Rogue Dwarf Planet',
      3 => 'Rogue Planetoid Cluster',
      4 => 'Rogue Planet',
      5 => 'Rogue Gas Giant',
      6 => 'Highly unusual large rogue body'
    }
    super(table: table, dice: 1, size: 6)
  end
end

class RogueObjectsTable < RollTable
  def initialize
    table = {
      2 => ->(roller:, **_) { Primary2Table.new.roll(roller:) },
      3..4 => 'Sensor glitch; nothing present',
      5..9 => 'Tiny ice-bearing comet suitable for one refuelling only',
      10..11 => 'Ice-bearing comet suitable for multiple refuelings',
      12 => ->(roller:, **_) { Primary12Table.new.roll(roller:) }
    }
    super(table: table, dice: 2, size: 6)
  end
end
