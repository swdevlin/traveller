json.partial! 'stellar_objects/stellar_object', stellar_object: @stellar_object

# The moons are listed a page at a time (moons.json.jbuilder), so the opened object only says how many.
unless @stellar_object.is_a?(Moon) || @stellar_object.is_a?(Star)
  json.moon_count @stellar_object.moons.count
  json.rings @stellar_object.rings.sort_by { |r| r.orbit.to_f } do |ring|
    json.extract! ring, :id, :name, :orbit
    json.span ring.span
  end
end
