# frozen_string_literal: true

trade_codes = [
  { code: 'As', definition: 'Asteroid Belt' },
  { code: 'De', definition: 'Desert' },
  { code: 'Fl', definition: 'Fluid' },
  { code: 'Ga', definition: 'Garden World' },
  { code: 'He', definition: 'Hellworld' },
  { code: 'Ic', definition: 'Ice-Capped' },
  { code: 'Oc', definition: 'Ocean World' },
  { code: 'Va', definition: 'Vacuum' },
  { code: 'Wa', definition: 'Water World' },
  { code: 'Sa', definition: 'Satellite' },
  { code: 'Lk', definition: 'Locked' },

  { code: 'Di', definition: 'Dieback (000-T)' },
  { code: 'Ba', definition: 'Barren' },
  { code: 'Lo', definition: 'Low Population' },
  { code: 'Ni', definition: 'Non-Industrial' },
  { code: 'Ph', definition: 'Pre-High' },
  { code: 'Hi', definition: 'High Population' },

  { code: 'Pa', definition: 'Pre-Agricultural' },
  { code: 'Ag', definition: 'Agricultural' },
  { code: 'Na', definition: 'Non-Agricultural' },
  { code: 'Px', definition: 'Prison or Exile Camp' },
  { code: 'Pi', definition: 'Pre-Industrial' },
  { code: 'In', definition: 'Industrial' },
  { code: 'Po', definition: 'Poor' },
  { code: 'Pr', definition: 'Pre-Rich' },
  { code: 'Ri', definition: 'Rich' },

  { code: 'Fr', definition: 'Frozen' },
  { code: 'Ho', definition: 'Hot' },
  { code: 'Co', definition: 'Cold' },
  { code: 'Tr', definition: 'Tropic' },
  { code: 'Tu', definition: 'Tundra' },
  { code: 'Tz', definition: 'Twilight Zone' },

  { code: 'Fa', definition: 'Farming' },
  { code: 'Mi', definition: 'Mining' },
  { code: 'Mr', definition: 'Military Rule' },
  { code: 'Pe', definition: 'Penal Colony' },
  { code: 'Re', definition: 'Reserve' },

  { code: 'Cp', definition: 'Subsector Capital' },
  { code: 'Cs', definition: 'Sector Capital' },
  { code: 'Cx', definition: 'Capital' },
  { code: 'Cy', definition: 'Colony' },

  { code: 'Fo', definition: 'Forbidden (Red Zone)' },
  { code: 'Pz', definition: 'Puzzle (Amber Zone)' },
  { code: 'Da', definition: 'Dangerous (Amber Zone)' },
  { code: 'Ab', definition: 'Data Repository' },
  { code: 'An', definition: 'Ancient Site' }
]

TradeCode.upsert_all(trade_codes, unique_by: :index_trade_codes_on_code)
