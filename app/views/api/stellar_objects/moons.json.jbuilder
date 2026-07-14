json.count @pagy.count
json.page  @pagy.page
json.pages @pagy.pages
json.moons @moons do |moon|
  json.partial! 'stellar_objects/stellar_object', stellar_object: moon
  json.orbit_type 11 # decode as TerrestrialPlanet client-side — moons and terrestrial planets share a detail view
  json.native_sophont moon.native_sophont == true
  json.extinct_sophont moon.extinct_sophont == true
  json.moons [] # moons don't have their own moons; client's SharedPData decoder requires the key
end
