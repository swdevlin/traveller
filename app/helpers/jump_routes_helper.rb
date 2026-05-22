# frozen_string_literal: true

module JumpRoutesHelper
  REFUELING_LABELS = {
    'any'        => 'Any',
    'commercial' => 'Commercial (D+ starport)',
    'refined'    => 'Refined only (A/B starport)',
    'wilderness' => 'Wilderness (gas giant)'
  }.freeze

  def refueling_label(code)
    REFUELING_LABELS.fetch(code, code.capitalize)
  end

  def star_system_search_label(system)
    return '' unless system

    system.name.presence || "#{system.parsec.sector.name} #{system.parsec.hex_code}"
  end
end
