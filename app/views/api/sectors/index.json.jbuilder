json.array! @sectors do |sector|
  json.(sector, :id, :name, :x, :y, :abbreviation)
  json.tags Current.referee_access? ? sector.tag_names : []
  json.subsectors sector.subsectors do |subsector|
    json.(subsector, :x, :y, :name)
    json.tags Current.referee_access? ? subsector.tag_names : []
  end
end
