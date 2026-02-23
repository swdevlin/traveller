class Subsector < ApplicationRecord
  include ClearableParsecs

  normalizes *attribute_names, with: -> { it.presence }

  validates :x, :y, :sector, presence: true
  belongs_to :sector

  validates :x, uniqueness: {
    scope: [:y, :sector_id],
    message: 'Subsector already exists'
  }

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
      .where(orbiting_star_id: nil)
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

  def load_sector_defaults!
    path = Rails.root.join('db', 'data', 'sector_defaults', "#{sector.x}_#{sector.y}.yaml")
    return unless File.exist?(path)

    data = YAML.safe_load(File.read(path))
    index = (('A'.ord) + (y - 1) * 4 + (x - 1)).chr
    entry = data['subsectors']&.find { |s| s['index'] == index }
    return unless entry

    self.name = entry['name']

    config = entry.except('name', 'index')
    config['unusualChance'] = data['unusualChance'] if data['unusualChance']
    config['defaultSI'] = data['defaultSI'] if data['defaultSI']
    normalize_config!(config)

    self.build = YAML.dump(config)
  end

  private

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
