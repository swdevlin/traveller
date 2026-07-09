json.array! @sectors do |sector|
  json.(sector, :id, :name, :x, :y, :abbreviation)
  json.subsectors sector.subsectors do |subsector|
    json.(subsector, :x, :y, :name)
  end
end
