class City < ApplicationRecord
  belongs_to :stellar_object

  TYPES = {
    'Ar' => { label: 'Arcology, sealed city', min_tl: 8 },
    'Fb' => { label: 'Flying, buoyant gas', min_tl: 8 },
    'Fg' => { label: 'Flying, grav hover', min_tl: 10 },
    'Fm' => { label: 'Flying, grav mobile', min_tl: 14 },
    'Mr' => { label: 'Mobile, rails', min_tl: 6 },
    'Mt' => { label: 'Mobile, tracked', min_tl: 9 },
    'Ss' => { label: 'Space, spin', min_tl: 8 },
    'Sg' => { label: 'Space, grav', min_tl: 10 },
    'Ub' => { label: 'Underground, benign environment', min_tl: 6 },
    'Uh' => { label: 'Underground, hostile environment', min_tl: 8 },
    'Wa' => { label: 'Water, shore floating adjacent', min_tl: 0 },
    'Wd' => { label: 'Water, static floating deep water', min_tl: 6 },
    'Wf' => { label: 'Water, free floating', min_tl: 8 },
    'Ws' => { label: 'Water, submerged', min_tl: 9 },
    'Wx' => { label: 'Water, deep ocean', min_tl: 12 }
  }.freeze

  CAPITAL_DESIGNATIONS = {
    'Cw' => 'World capital',
    'Cf' => 'Faction capital',
    'Cn' => 'National capital',
    'Cr' => 'Regional capital'
  }.freeze

  validates :language, inclusion: { in: -> { WordGenerator.languages.map(&:to_s) }, allow_blank: true }
  validates :population, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :city_type, inclusion: { in: TYPES.keys }, allow_blank: true
  validates :capital_designation, inclusion: { in: CAPITAL_DESIGNATIONS.keys }, allow_blank: true


  def type_label
    city_type.present? ? TYPES.dig(city_type, :label) : 'Standard'
  end

  def capital_label
    CAPITAL_DESIGNATIONS[capital_designation]
  end

  def effective_language(campaign)
    language.presence || stellar_object.effective_language(campaign)
  end
end
