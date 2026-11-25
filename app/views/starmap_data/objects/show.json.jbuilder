json.partial! 'stellar_objects/stellar_object', stellar_object: @stellar_object

# The moons are listed a page at a time (moons.json.jbuilder), so the opened object only says how many.
if @stellar_object.is_a?(Moon)
  # a moon is opened like a terrestrial planet, as in the API's moons list
  json.orbit_type 11
  json.native_sophont @stellar_object.native_sophont == true
  json.extinct_sophont @stellar_object.extinct_sophont == true
elsif !@stellar_object.is_a?(Star)
  json.moon_count @stellar_object.moons.count
  json.rings @stellar_object.rings.sort_by { |r| r.orbit.to_f } do |ring|
    json.extract! ring, :id, :name, :orbit
    json.span ring.span
  end
end
