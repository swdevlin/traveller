# One row per moon: what the Moons tab lists. A moon is fetched in full (objects#show) when clicked.
json.count @pagy.count
json.page  @pagy.page
json.pages @pagy.pages
json.parent_diameter_km @parent_diameter_km
json.moons @moons.select { |body| body.is_a?(Moon) } do |moon|
  json.extract! moon, :id, :name, :uwp, :orbit
  json.orbit_sequence moon.orbit_sequence || ''
end
json.rings @moons.select { |body| body.is_a?(Ring) } do |ring|
  json.extract! ring, :id, :name, :orbit
  json.span ring.span
end
