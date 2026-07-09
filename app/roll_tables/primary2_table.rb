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
