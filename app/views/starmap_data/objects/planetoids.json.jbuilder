# One row per planetoid: what the Planetoids tab lists. A planetoid is fetched in full (objects#show) when clicked.
# Read with pluck: a planetoid record is mostly generator data, and building one casts all of it.
json.count @pagy.count
json.page  @pagy.page
json.pages @pagy.pages
rows = @planetoids.pluck(:id, :size_code, :orbit_sequence, :au, :uwp,
                         Arel.sql("data -> 'native_sophont'"), Arel.sql("data -> 'extinct_sophont'"))
json.planetoids rows do |id, size_code, orbit_sequence, au, uwp, native, extinct|
  json.id id
  json.size_code size_code
  json.orbit_sequence orbit_sequence || ''
  json.au au
  json.uwp uwp
  json.native_sophont native == true
  json.extinct_sophont extinct == true
end
