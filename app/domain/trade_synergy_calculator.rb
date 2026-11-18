# frozen_string_literal: true

# Finds which goods would flow profitably between a system and its neighbours,
# in each direction. Deterministic: it uses only the purchase and sale DMs of
# each world's trade codes (see TradeGoodsTable), never dice.
#
# A good flows from A to B when A's net purchase DM plus B's net sale DM is
# positive, where a world's net purchase DM is its best purchase DM less its
# best sale DM for that good, and its net sale DM is the reverse. This mirrors
# the sign convention in TradePriceCalculator. A good can only leave a world
# where it is available for purchase (see TradeAvailabilityCalculator).
class TradeSynergyCalculator
  include HexDistance

  # +from_codes+ are the seller's trade codes. When given, only goods the seller
  # can actually buy are considered: Common Goods plus Trade Goods whose
  # Availability codes match. Goods found by random Population rolls are not
  # counted, as they cannot be predicted.
  def self.goods_flowing(from_dms, to_dms, from_codes: nil)
    from_dms.keys.union(to_dms.keys).filter_map do |d66|
      next unless available?(d66, from_codes)

      from = from_dms.fetch(d66, { purchase_dm: 0, sale_dm: 0 })
      to = to_dms.fetch(d66, { purchase_dm: 0, sale_dm: 0 })
      bonus = (from[:purchase_dm] - from[:sale_dm]) + (to[:sale_dm] - to[:purchase_dm])
      next unless bonus.positive?

      good = TradeGoodsTable.for(d66)
      { d66: d66, name: good[:name], category: good[:category].to_s, bonus: bonus }
    end.sort_by { |g| [-g[:bonus], g[:d66]] }
  end

  def self.available?(d66, codes)
    return true if codes.nil?

    availability = TradeGoodsTable.for(d66)[:availability]
    availability == :all || (Array(availability) & codes).any?
  end

  # Systems with a main world within +jump+ parsecs of +origin+ (excluding
  # origin), in kept sectors, preloaded for #calculate.
  def self.partners_within(origin, jump)
    ox = origin.parsec.x
    oy = origin.parsec.y
    finder = new(origin: origin, partners: [])
    StarSystem.joins(parsec: :sector).merge(Sector.kept)
      .where(parsecs: { x: (ox - jump)..(ox + jump), y: (oy - jump)..(oy + jump) })
      .where.not(main_world_id: nil).where.not(id: origin.id)
      .includes({ parsec: :sector }, :travel_zone, main_world: :trade_codes)
      .select { finder.hex_distance([ox, oy], [it.parsec.x, it.parsec.y]) <= jump }
  end

  def self.dms_by_d66(system)
    TradeGoodsTable.dms_for(system.trade_dm_codes).index_by { it[:d66] }
  end

  def initialize(origin:, partners:)
    @origin = origin
    @partners = partners
  end

  # @return [Hash] { origin:, partners: } where each partner carries its
  #   distance, outbound/inbound goods, counts and total bonuses
  def calculate
    origin_dms = self.class.dms_by_d66(@origin)

    rows = @partners.map { partner_row(it, origin_dms) }
    rows.sort_by! { [-(it[:outbound_count] + it[:inbound_count]), it[:distance], it[:name].to_s] }

    { origin: system_json(@origin), partners: rows }
  end

  private

  def partner_row(partner, origin_dms)
    partner_dms = self.class.dms_by_d66(partner)
    outbound = self.class.goods_flowing(origin_dms, partner_dms, from_codes: codes_for(@origin))
    inbound = self.class.goods_flowing(partner_dms, origin_dms, from_codes: codes_for(partner))

    system_json(partner).merge(
      distance: hex_distance([@origin.parsec.x, @origin.parsec.y], [partner.parsec.x, partner.parsec.y]),
      outbound_count: outbound.size,
      outbound_bonus: outbound.sum { it[:bonus] },
      inbound_count: inbound.size,
      inbound_bonus: inbound.sum { it[:bonus] },
      outbound_goods: outbound,
      inbound_goods: inbound
    )
  end

  def codes_for(system)
    system.trade_codes.map(&:code)
  end

  def system_json(system)
    parsec = system.parsec
    {
      id: system.id,
      name: system.name,
      hex: parsec.hex_code,
      sector: parsec.sector.name,
      origin_x: parsec.x,
      origin_y: parsec.y,
      uwp: system.main_world_uwp,
      starport: system.main_world_starport_code,
      gas_giant: system.has_gas_giant?,
      travel_zone: system.travel_zone&.code,
      trade_codes: system.trade_codes.map(&:code).sort
    }
  end
end
