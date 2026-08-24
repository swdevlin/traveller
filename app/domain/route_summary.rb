# frozen_string_literal: true

class RouteSummary
  include HexDistance

  Hop = Struct.new(:from_coord, :to_coord, :from_sector_id, :to_sector_id, :from_system_id, :to_system_id,
                    :from_starport, :to_starport, :from_population, :to_population,
                    keyword_init: true)

  def initialize(hops)
    @hops = hops
  end

  def number_of_jumps       = @hops.size
  def number_of_sectors     = sector_ids.uniq.size
  def number_of_systems     = system_ids.uniq.size
  def total_distance        = lengths.sum
  def length_histogram      = lengths.tally.sort.to_h
  def link_count_histogram  = system_ids.tally.values.tally.sort.to_h
  def starport_histogram    = codes_by_system(:starport).values.compact.tally.sort.to_h
  def population_histogram  = codes_by_system(:population).values.compact.tally.sort.to_h
  def facility_histogram    = StarSystemFacility.where(star_system_id: system_ids.uniq).group(:facility_id).count

  private

  def lengths    = @hops.map { |h| hex_distance(h.from_coord, h.to_coord) }
  def sector_ids = @hops.flat_map { |h| [h.from_sector_id, h.to_sector_id] }
  def system_ids = @hops.flat_map { |h| [h.from_system_id, h.to_system_id] }

  def codes_by_system(attr)
    @hops.each_with_object({}) do |h, codes|
      codes[h.from_system_id] ||= h.public_send(:"from_#{attr}")
      codes[h.to_system_id]   ||= h.public_send(:"to_#{attr}")
    end
  end
end
