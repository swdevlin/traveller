json.count @pagy.count
json.page  @pagy.page
json.pages @pagy.pages
json.parent_diameter_km @parent_diameter_km
# rings are listed under their own key so clients that only read `moons` are unaffected; both are in orbit order
json.moons @moons.select { |body| body.is_a?(Moon) } do |moon|
  json.partial! 'stellar_objects/stellar_object', stellar_object: moon
  json.orbit_type 11 # decode as TerrestrialPlanet client-side — moons and terrestrial planets share a detail view
  json.native_sophont moon.native_sophont == true
  json.extinct_sophont moon.extinct_sophont == true
  json.moons [] # moons don't have their own moons; client's SharedPData decoder requires the key
end
json.rings @moons.select { |body| body.is_a?(Ring) } do |ring|
  json.partial! 'stellar_objects/stellar_object', stellar_object: ring
  json.span ring.span
end
