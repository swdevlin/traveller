# frozen_string_literal: true

module OrbitType
  VALUES = {
    primary: 0,
    close: 1,
    near: 2,
    far: 3,
    companion: 4,
    gas_giant: 10,
    terrestrial_planet: 11,
    planetoid_belt: 12,
    planetoid: 13
  }.freeze

  STI_CLASS_FOR_ORBIT_TYPE = {
    VALUES[:gas_giant] => GasGiant,
    VALUES[:planetoid_belt] => PlanetoidBelt,
    VALUES[:planetoid] => Planetoid,
    VALUES[:terrestrial_planet] => TerrestrialPlanet,
    VALUES[:primary] => Star,
    VALUES[:close] => Star,
    VALUES[:near] => Star,
    VALUES[:far] => Star
  }.freeze

  # Stellar Orbit# ranges for non-primary, non-companion stars
  # (World Builder's Handbook, pg. 27):
  #   Close: 1D-1  -> Orbit# 0.5-5
  #   Near:  1D+5  -> Orbit# 6-11
  #   Far:   1D+11 -> Orbit# 12-17
  # Each band may carry an optional +0.5 fractional Orbit# variance, but the
  # bands themselves never overlap, so a star's close/near/far role can be
  # recovered from its persisted Orbit# alone - no need to store the role
  # separately.
  ORBIT_ROLE_RANGES = {
    (0...6) => :close,
    (6...12) => :near,
    (12..) => :far
  }.freeze

  # Returns :close, :near, :far, or nil (for a nil orbit, or one outside the
  # documented bands) for a secondary star's persisted Orbit#.
  def self.role_for_orbit(orbit)
    return nil if orbit.nil?

    ORBIT_ROLE_RANGES.each do |range, role|
      return role if range.cover?(orbit)
    end
    nil
  end
end
