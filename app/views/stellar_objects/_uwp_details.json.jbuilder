gov       = stellar_object.government_code.present? ? Government.find_by(code: stellar_object.government_code) : nil
law_index = LawLevel.all.index_by(&:code)
tl_code      = stellar_object.tech_level_code
tl_main      = tl_code.present? ? TechLevel.find_by(code: tl_code) : nil
tl_data      = stellar_object.data&.dig('tech_level') || {}
tl_cap_codes = tl_data.values.grep(Integer).uniq
tl_index     = TechLevel.where(code: tl_cap_codes).index_by(&:code)

sp_code = stellar_object.starport_code.presence || 'X'
sp      = StellarObjectsHelper::STARPORT_DATA[sp_code] || StellarObjectsHelper::STARPORT_DATA['X']
json.starport do
  json.label      'Starport'
  json.code       sp_code
  json.quality    sp[:quality]
  json.fuel       sp[:fuel]
  json.facilities sp[:facilities]
end

json.size do
  json.label       'Size'
  json.code        stellar_object.size_code
  json.description StellarObjectsHelper::SIZE_DESCRIPTIONS[stellar_object.size_code]
end

atm_code = stellar_object.atmosphere_code
json.atmosphere do
  json.label       'Atmosphere'
  json.code        atm_code
  json.description StellarObjectsHelper::ATMOSPHERE_DESCRIPTIONS[atm_code]
  json.survival_requirement do
    json.label 'Survival Requirement'
    json.value atmosphere_survival_requirement(atm_code, tainted: stellar_object.atmosphere_taint_code.present?)
  end
  if stellar_object.atmosphere_composition.present?
    json.composition do
      json.label 'Composition'
      json.value stellar_object.atmosphere_composition
    end
  end
  tc = stellar_object.atmosphere_taint_code
  if tc.present?
    json.taint do
      json.label       'Irritant'
      json.code        tc
      json.description StellarObjectsHelper::TAINT_DESCRIPTIONS[tc]
      sev = stellar_object.atmosphere_taint_severity
      if sev.present?
        json.severity do
          json.label       'Severity'
          json.code        sev
          json.description StellarObjectsHelper::TAINT_SEVERITY_DESCRIPTIONS[sev]
        end
      end
      per = stellar_object.atmosphere_taint_persistence
      if per.present?
        json.persistence do
          json.label       'Persistence'
          json.code        per
          json.description StellarObjectsHelper::TAINT_PERSISTENCE_DESCRIPTIONS[per]
        end
      end
    end
  end
end

hydro_code = stellar_object.hydrographics_code
json.hydrographics do
  json.label       'Hydrographics'
  json.code        hydro_code
  json.description StellarObjectsHelper::HYDROGRAPHICS_DESCRIPTIONS[hydro_code]
  if stellar_object.hydrographics_liquid.present?
    json.liquid do
      json.label 'Liquid'
      json.value stellar_object.hydrographics_liquid
    end
  end
  dist = stellar_object.hydrographics_distribution
  if dist.present?
    json.distribution do
      json.label       'Distribution'
      json.code        dist
      json.description StellarObjectsHelper::HYDROGRAPHICS_DISTRIBUTION_DESCRIPTIONS[dist]
    end
  end
end

pop_code = stellar_object.population_code
json.population do
  json.label 'Population'
  json.code  pop_code
  json.range StellarObjectsHelper::POPULATION_RANGES[pop_code]
  cr = stellar_object.population_concentration_rating
  if cr.present?
    json.concentration_rating do
      json.label       'Concentration Rating'
      json.code        cr
      json.description StellarObjectsHelper::CONCENTRATION_RATING_DESCRIPTIONS[cr.to_i]
    end
  end
  if stellar_object.population_urbanization_percentage.present?
    json.urbanization_percentage do
      json.label 'Urbanization %'
      json.value stellar_object.population_urbanization_percentage
    end
  end
  if stellar_object.population_major_cities.present?
    json.major_cities do
      json.label 'Major Cities'
      json.value stellar_object.population_major_cities
    end
  end
  if stellar_object.population_major_city_population.present?
    json.major_city_population do
      json.label 'Major City Population'
      json.value stellar_object.population_major_city_population
    end
  end
  if stellar_object.respond_to?(:native_sophont)
    json.native_sophont do
      json.label 'Native Sophont'
      json.value stellar_object.native_sophont
    end
    json.extinct_sophont do
      json.label 'Extinct Sophont'
      json.value stellar_object.extinct_sophont
    end
  end
  if stellar_object.respond_to?(:population_diversity)
    traits = StellarObjectsHelper::CULTURE_TRAIT_DATA.filter_map do |t|
      val = stellar_object.send(t[:getter])
      next unless val.present?
      { label: t[:label], code: t[:code], value: val, low_label: t[:low_label], high_label: t[:high_label], min: t[:min], max: t[:max] }
    end
    if traits.any?
      json.culture do
        json.label  'Culture'
        json.traits traits
      end
    end
  end
  if stellar_object.respond_to?(:habitability_rating)
    json.biological_data do
      json.label 'Biological Data'
      if stellar_object.habitability_rating.present?
        json.habitability_rating do
          json.label       'Habitability Rating'
          json.code        stellar_object.habitability_rating
          json.description StellarObjectsHelper::HABITABILITY_RATING_DESCRIPTIONS[stellar_object.habitability_rating]
        end
      end
      if stellar_object.biomass_rating.present?
        json.biomass_rating do
          json.label 'Biomass Rating'
          json.value stellar_object.biomass_rating
        end
      end
      if stellar_object.biodiversity_rating.present?
        json.biodiversity_rating do
          json.label       'Biodiversity Rating'
          json.code        stellar_object.biodiversity_rating
          json.description biodiversity_description(stellar_object.biodiversity_rating)
        end
      end
      if stellar_object.biocomplexity_rating.present?
        json.biocomplexity_rating do
          json.label       'Biocomplexity Rating'
          json.code        stellar_object.biocomplexity_rating
          json.description StellarObjectsHelper::BIOCOMPLEXITY_DESCRIPTIONS[stellar_object.biocomplexity_rating]
        end
      end
      if stellar_object.resource_rating.present?
        json.resource_rating do
          json.label       'Resource Rating'
          json.code        stellar_object.resource_rating
          json.description StellarObjectsHelper::RESOURCE_RATING_DESCRIPTIONS[stellar_object.resource_rating]
        end
      end
    end
  end
end

json.government do
  json.label 'Government'
  json.code  stellar_object.government_code
  if gov
    json.type        gov.government_type
    json.description gov.description
  end
  judicial    = stellar_object.government_judicial
  executive   = stellar_object.government_executive
  legislative = stellar_object.government_legislative
  if judicial || executive || legislative
    json.structure do
      json.label 'Structure'
      if judicial
        json.judicial do
          json.label       'Judicial'
          json.code        judicial
          json.description StellarObjectsHelper::GOVERNMENT_STRUCTURE_DESCRIPTIONS[judicial]
        end
      end
      if executive
        json.executive do
          json.label       'Executive'
          json.code        executive
          json.description StellarObjectsHelper::GOVERNMENT_STRUCTURE_DESCRIPTIONS[executive]
        end
      end
      if legislative
        json.legislative do
          json.label       'Legislative'
          json.code        legislative
          json.description StellarObjectsHelper::GOVERNMENT_STRUCTURE_DESCRIPTIONS[legislative]
        end
      end
    end
  end
  authority      = stellar_object.government_authority
  centralisation = stellar_object.government_centralisation
  if authority || centralisation
    json.characteristics do
      json.label 'Characteristics'
      if authority
        json.authority do
          json.label       'Authority'
          json.code        authority
          json.description StellarObjectsHelper::GOVERNMENT_AUTHORITY_DESCRIPTIONS[authority]
        end
      end
      if centralisation
        json.centralisation do
          json.label       'Centralisation'
          json.code        centralisation
          json.description StellarObjectsHelper::GOVERNMENT_CENTRALISATION_DESCRIPTIONS[centralisation]
        end
      end
    end
  end
end

ll_code = stellar_object.law_level_code
json.law_level do
  json.label 'Law Level'
  json.code  ll_code
  json.sub_classifications do
    json.label 'Sub-Classifications'
    [
      ['weapons_and_armour', 'Weapons & Armour', :law_level_weapons_and_armour, :weapons],
      ['criminal_law',       'Criminal Law',     :law_level_criminal_law,       :criminal_law],
      ['economic_law',       'Economic Law',     :law_level_economic_law,       :economic_law],
      ['private_law',        'Private Law',      :law_level_private_law,        :private_law],
      ['personal_rights',    'Personal Rights',  :law_level_personal_rights,    :personal_law]
    ].each do |json_key, label, accessor, law_col|
      sub_code = stellar_object.send(accessor)
      next unless sub_code
      record = law_index[sub_code]
      json.set! json_key do
        json.label       label
        json.code        sub_code
        json.description record&.public_send(law_col)
      end
    end
  end
  json.characteristics do
    json.label 'Characteristics'
    unif = stellar_object.law_level_uniformity
    if unif.present?
      json.uniformity do
        json.label       'Law Uniformity'
        json.code        unif
        json.description StellarObjectsHelper::LAW_UNIFORMITY_DESCRIPTIONS[unif]
      end
    end
    jud = stellar_object.law_level_judicial_system
    if jud.present?
      json.judicial_system do
        json.label       'Judicial System'
        json.code        jud
        json.description StellarObjectsHelper::LAW_JUDICIAL_SYSTEM_DESCRIPTIONS[jud]
      end
    end
    unless stellar_object.law_level_death_penalty.nil?
      json.death_penalty do
        json.label 'Death Penalty'
        json.value stellar_object.law_level_death_penalty
      end
    end
    unless stellar_object.law_level_presumed_innocence.nil?
      json.presumed_innocence do
        json.label 'Presumed Innocence'
        json.value stellar_object.law_level_presumed_innocence
      end
    end
    unless stellar_object.law_level_econometric_infractions_administrative.nil?
      json.econometric_infractions_administrative do
        json.label 'Econometric Infractions Administrative'
        json.value stellar_object.law_level_econometric_infractions_administrative
      end
    end
  end
end

json.tech_level do
  json.label      'Tech Level'
  json.code       tl_code
  json.descriptor tl_main&.descriptor
  {
    'energy'            => 'Energy',
    'electronics'       => 'Electronics',
    'manufacturing'     => 'Manufacturing',
    'medical'           => 'Medical',
    'environmental'     => 'Environmental',
    'land'              => 'Land Transport',
    'sea'               => 'Water Transport',
    'air'               => 'Air Transport',
    'space'             => 'Space Transport',
    'personal_military' => 'Personal Military',
    'heavy_military'    => 'Heavy Military'
  }.each do |key, label|
    cap_code = tl_data[key]
    next unless cap_code
    rec = tl_index[cap_code]
    json.set! key do
      json.label       label
      json.code        cap_code
      json.description rec&.public_send(key)
    end
  end
end

econ = stellar_object.data&.dig('economics')
if econ.present?
  json.economics do
    json.label 'Economics'
    if stellar_object.world_trade_number.present?
      json.world_trade_number do
        json.label 'World Trade Number'
        json.value stellar_object.world_trade_number
      end
    end
    if stellar_object.importance.present?
      json.importance do
        json.label 'Importance'
        json.value stellar_object.importance
      end
    end
    if stellar_object.development_score.present?
      json.development_score do
        json.label 'Development Score'
        json.value stellar_object.development_score
      end
    end
    if stellar_object.per_capita_gwp.present?
      json.per_capita_gwp do
        json.label 'Per Capita GWP'
        json.value stellar_object.per_capita_gwp
      end
    end
    if stellar_object.total_gwp.present?
      json.total_gwp do
        json.label 'Total GWP'
        json.value stellar_object.total_gwp
      end
    end
    if stellar_object.infrastructure.present?
      json.infrastructure do
        json.label 'Infrastructure'
        json.value stellar_object.infrastructure
      end
    end
    if stellar_object.resource_units.present?
      json.resource_units do
        json.label 'Resource Units'
        json.value stellar_object.resource_units
      end
    end
    if stellar_object.resource_factor.present?
      json.resource_factor do
        json.label 'Resource Factor'
        json.value stellar_object.resource_factor
      end
    end
    if stellar_object.labour_factor.present?
      json.labour_factor do
        json.label 'Labour Factor'
        json.value stellar_object.labour_factor
      end
    end
    if stellar_object.efficiency.present?
      json.efficiency do
        json.label 'Efficiency'
        json.value stellar_object.efficiency
      end
    end
    if stellar_object.inequality_rating.present?
      json.inequality_rating do
        json.label 'Inequality Rating'
        json.value stellar_object.inequality_rating
      end
    end
    if stellar_object.tariff_regime.present?
      json.tariff_regime do
        json.label 'Tariff Regime'
        json.value stellar_object.tariff_regime
      end
    end
    if stellar_object.tariff_rate.present?
      json.tariff_rate do
        json.label 'Tariff Rate'
        json.value stellar_object.tariff_rate
      end
    end
  end
end
