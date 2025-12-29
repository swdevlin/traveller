# frozen_string_literal: true

class GasGiantSizeTable < RollTable
  def initialize
    table = {
      2 => 'GS',
      3..4 => 'GM',
      5 => 'GL'
    }
    super(table: table, dice: 1, size: 6)
  end
end
