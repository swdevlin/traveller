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
end
