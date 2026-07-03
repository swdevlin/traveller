class Sector < ApplicationRecord
  include Discard::Model
  include ClearableParsecs
  validates :x, :y, presence: true
  validates :language, inclusion: { in: -> { WordGenerator.languages.map(&:to_s) }, allow_blank: true }
  has_many :subsectors, dependent: :destroy
  has_many :parsecs, dependent: :destroy

  attr_accessor :skip_subsector_creation, :default_build_spec
  after_create_commit :create_subsectors_and_parsecs, unless: :skip_subsector_creation
  after_update_commit :shift_parsec_coordinates, if: -> { saved_change_to_x? || saved_change_to_y? }

  validate :coordinates_unique_with_link
  validate :traveller_map_accessible, if: -> { source == 'traveller_map' && new_record? && x.present? && y.present? }

  def effective_language(campaign)
    language.presence || campaign.default_language.presence
  end

  def wiki_link
    "https://wiki.travellerrpg.com/#{name.tr(' ', '_')}_Sector"
  end

  def traveller_map_url
    "https://travellermap.com/go/#{name.tr(' ', '+')}"
  end

  def universal_coordinates
    ul = Coordinate.new(x*32, y*40)
    lr = ul.clone
    lr.x += 31
    lr.y -= 39

    [ul, lr]
  end

  def upper_left
    Coordinate.new(x*32, y*40)
  end

  def hexes
    ul, lr = universal_coordinates
    Parsec.where(x: ul.x..lr.x, y: lr.y..ul.y)
  end

  def neighbours
    Sector
        .where(x: (x-1..x+1), y: (y-1..y+1))
        .index_by { |s| [s.x, s.y] }
  end

  def get_allegiances
    Allegiance
      .joins(star_systems: :parsec)
      .where(parsecs: { sector_id: id })
      .where.not(allegiances: { id: nil })
      .distinct
  end

  private

  def coordinates_unique_with_link
    return if x.blank? || y.blank?

    existing = Sector.kept.where(x: x, y: y).where.not(id: id).first
    if existing
      safe_name = ERB::Util.h(existing.name)
      path = Rails.application.routes.url_helpers.sector_path(existing)
      errors.add(:base, %(<a href="#{path}">#{safe_name}</a> already exists at #{x}/#{y}.))
      return
    end

    if Sector.discarded.where(x: x, y: y).where.not(id: id).exists?
      errors.add(:base, "A sector at #{x}/#{y} is still being deleted. Please wait a moment and try again.")
    end
  end

  def shift_parsec_coordinates
    x_old, x_new = saved_changes['x'] || [x, x]
    y_old, y_new = saved_changes['y'] || [y, y]
    x_delta = (x_new - x_old) * 32
    y_delta = (y_new - y_old) * 40
    return if x_delta.zero? && y_delta.zero?

    parsecs.update_all(['x = x + ?, y = y + ?', x_delta, y_delta])
  end

  def traveller_map_accessible
    @traveller_map_subsectors = fetch_subsector_names_from_traveller_map
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, JSON::ParserError => e
    Rails.logger.warn "TravellerMap unreachable for #{x}/#{y}: #{e.message}"
    errors.add(:base, 'Traveller Map is currently unreachable. Please try again later.')
  end

  def create_subsectors_and_parsecs
    if source == 'traveller_map' && @traveller_map_sector_metadata.present?
      SectorRouteImporter.new(self, @traveller_map_sector_metadata).call
    end

    return if Rails.env.test?

    subsector_names = instance_variable_defined?(:@traveller_map_subsectors) ? @traveller_map_subsectors : fetch_subsector_names_from_traveller_map if source == 'traveller_map'

    ('A'..'P').each_with_index do |letter, index|
      sx = (index % 4) + 1
      sy = (index / 4) + 1
      subsector_name = subsector_names&.dig(letter, 'Name')
      CreateSubsectorJob.perform_later(id, letter, sx, sy, subsector_name, default_build_spec)
    end
  end

  def fetch_subsector_names_from_traveller_map
    traveller_map = TravellerMap.new
    @traveller_map_sector_metadata = traveller_map.fetch_sector_metadata(x, y)

    if @traveller_map_sector_metadata.blank?
      errors.add(:base, 'Traveller Map is currently unreachable. Please try again later.')
      return nil
    end

    (@traveller_map_sector_metadata['Subsectors'] || []).index_by { |s| s['Index'] }
  end
end
