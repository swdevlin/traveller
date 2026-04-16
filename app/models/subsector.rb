class Subsector < ApplicationRecord
  include ClearableParsecs

  normalizes *attribute_names, with: -> { it.presence }

  validates :x, :y, :sector, presence: true
  belongs_to :sector

  scope :with_build, -> { where.not(build: nil) }
  scope :kept_sector, -> { joins(:sector).where(sectors: { discarded_at: nil }) }

  validates :x, uniqueness: {
    scope: [:y, :sector_id],
    message: 'Subsector already exists'
  }

  def spinward
    return sector.subsectors.find_by(x: x - 1, y: y) if x > 1

    Sector.kept.find_by(x: sector.x - 1, y: sector.y)&.subsectors&.find_by(x: 4, y: y)
  end

  def trailing
    return sector.subsectors.find_by(x: x + 1, y: y) if x < 4

    Sector.kept.find_by(x: sector.x + 1, y: sector.y)&.subsectors&.find_by(x: 1, y: y)
  end

  def coreward
    return sector.subsectors.find_by(x: x, y: y - 1) if y > 1

    Sector.kept.find_by(x: sector.x, y: sector.y + 1)&.subsectors&.find_by(x: x, y: 4)
  end

  def rimward
    return sector.subsectors.find_by(x: x, y: y + 1) if y < 4

    Sector.kept.find_by(x: sector.x, y: sector.y - 1)&.subsectors&.find_by(x: x, y: 1)
  end

  def star_systems_scope
    ul, lr = universal_coordinates
    in_subsector = { x: ul.x..lr.x, y: lr.y..ul.y }

    StarSystem
      .joins(:parsec)
      .where(parsecs: in_subsector)
  end

  def universal_coordinates
    ul,  = sector.universal_coordinates
    ul = ul.dup
    ul.x += (x-1)* 8
    ul.y -= (y-1) * 10
    lr = Coordinate.new(x: ul.x+7, y: ul.y-9)
    return ul, lr
  end

  def parsecs
    ul, lr = universal_coordinates
    Parsec.where(x: ul.x..lr.x, y: lr.y..ul.y)
  end

  def rogues
    ul, lr = universal_coordinates
    in_subsector = { x: ul.x..lr.x, y: lr.y..ul.y }
    StellarObject
      .joins(:parsec)
      .where(parsecs: in_subsector)
      .where(orbiting_id: nil)
      .order('parsecs.x ASC, parsecs.y DESC')
  end

  def star_systems
    ul, lr = universal_coordinates
    in_subsector = { x: ul.x..lr.x, y: lr.y..ul.y }
    StarSystem
      .joins(:parsec)
      .where(parsecs: in_subsector)
      .order('parsecs.x ASC, parsecs.y DESC')
  end

  def number_of_star_systems
    star_systems.count
  end

  def number_of_populated_star_systems
    star_systems
      .where(
        id: StellarObject
          .where("(data -> 'population' ->> 'code')::integer > 0")
          .select(:star_system_id)
      )
      .count
  end

  def number_of_stars
    ul, lr = universal_coordinates
    in_subsector = { x: ul.x..lr.x, y: lr.y..ul.y }

    Star
      .joins(star_system: :parsec)
      .where(parsecs: in_subsector)
      .count
  end

  def allegiances
    ul, lr = universal_coordinates
    in_subsector = { x: ul.x..lr.x, y: lr.y..ul.y }

    Allegiance
      .joins(star_systems: :parsec)
      .where(parsecs: in_subsector.merge(sector_id: sector_id))
      .where.not(allegiances: { id: nil })
      .distinct
  end

  def wiki_link
    "https://wiki.travellerrpg.com/#{name.tr(' ', '_')}_Subsector"
  end

  def load_deepnight_defaults!
    data = deepnight_sector_data
    return unless data

    apply_deepnight_defaults!(data)
  end

  def apply_deepnight_defaults!(data)
    index = (('A'.ord) + (y - 1) * 4 + (x - 1)).chr
    entry = data['subsectors']&.find { |s| s['index'] == index }
    return unless entry

    self.name = entry['name']

    config = entry.except('name', 'index')
    config['unusualChance'] = data['unusualChance'] if !config.key?('unusualChance') && data['unusualChance']
    config['defaultSI']     = data['defaultSI']     if !config.key?('defaultSI') && data['defaultSI']
    config['populated']     = data['populated']     if !config.key?('populated') && data['populated'].present?
    normalize_config!(config)

    ensure_populated_allegiances(config)
    self.build = YAML.dump(config)
    self.build_source = 'deepnight_books'
  end

  def load_travellermap_defaults!
    letter = (('A'.ord) + (y - 1) * 4 + (x - 1)).chr
    traveller_map = TravellerMap.new
    systems = traveller_map.fetch_subsector_systems(sector.x, sector.y, letter)
    return if systems.empty?

    traveller_map.ensure_allegiances(systems)
    traveller_map.ensure_travel_zones(systems)
    self.build = traveller_map.systems_to_build_plan(systems)
    self.build_source = 'traveller_map'
  end

  private

  def deepnight_sector_data
    path = Rails.root.join('db', 'data', 'sector_defaults', "#{sector.x}_#{sector.y}.yaml")
    return nil unless File.exist?(path)

    YAML.safe_load(File.read(path))
  end

  def ensure_populated_allegiances(config)
    pop = config['populated']
    return if pop.nil?

    codes = []
    codes << pop['allegiance']
    %w[before after].each do |region|
      codes << pop.dig(region, 'allegiance')
    end

    codes.compact.uniq.each do |code|
      Allegiance.find_or_create_by!(code: code) { |a| a.name = code }
    end
  end

  def tm_build_system(sys)
    hex = sys['Hex']
    return nil if hex.blank?

    hx = ((hex[0, 2].to_i - 1) % 8) + 1
    hy = ((hex[2, 2].to_i - 1) % 10) + 1
    entry = { 'x' => hx, 'y' => hy }

    entry['name'] = sys['Name'] if sys['Name'].present?

    pbg = sys['PBG']
    unless pbg.blank? || pbg == '???'
      entry['counts'] = {
        'mainWorld' => { 'uwp' => sys['UWP'], 'orbit' => 'hzco', 'name' => sys['Name'] },
        'terrestrialPlanets' => pbg[0].to_i,
        'planetoidBelts' => pbg[1].to_i,
        'gasGiants' => pbg[2].to_i
      }
      stars = tm_parse_stars(sys['Stars'])
      if stars.any?
        entry['primary'] = stars[0]
        case stars.length
        when 2
          entry['primary']['near'] = stars[1]
        when 3
          entry['primary']['near'] = stars[1]
          entry['primary']['far'] = stars[2]
        when 4..
          entry['primary']['close'] = stars[1]
          entry['primary']['near'] = stars[2]
          entry['primary']['far'] = stars[3]
        end
      end
    end

    entry['bases'] = sys['Bases'].chars if sys['Bases'].present?
    entry['allegiance'] = sys['Allegiance'] if sys['Allegiance'].present?

    entry
  end

  def tm_parse_stars(stars)
    return [] if stars.blank?

    stars.split.each_slice(2).filter_map do |type, klass|
      next unless type && klass
      { 'type' => type, 'class' => klass }
    end
  end

  def normalize_config!(node)
    case node
    when Hash
      normalize_bodies!(node)
      normalize_bases!(node)
      normalize_star!(node)
      node.each_value { |v| normalize_config!(v) }
    when Array
      node.each { |v| normalize_config!(v) }
    end
  end

  def normalize_bodies!(node)
    return unless node['bodies'].is_a?(Array)

    node['bodies'] = node['bodies'].map do |body|
      if body.is_a?(String)
        { 'uwp' => normalize_uwp_label(body) }
      elsif body.is_a?(Hash) && body['uwp'] && !uwp_code?(body['uwp'])
        body['uwp'] = normalize_uwp_label(body['uwp'])
        body
      else
        body
      end
    end
  end

  def normalize_bases!(node)
    return unless node['bases'].is_a?(String)

    node['bases'] = node['bases'].chars
  end

  def normalize_star!(node)
    return unless node['type'].is_a?(String)
    return unless node['type'].match?(/\A[OBAFGKM]\d\z/)
    return if node.key?('class')

    node['class'] = 'V'
  end

  def uwp_code?(value)
    value.match?(/\A[0-9A-Za-z][0-9A-Fa-f]{6}-[0-9A-Fa-f]\z/)
  end

  def normalize_uwp_label(value)
    value.downcase.tr('-', ' ')
  end
end
