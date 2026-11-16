json.array! @sectors do |sector|
  json.(sector, :id, :name, :x, :y, :abbreviation)
  json.partial! 'api/records', record: sector, html: false
  json.subsectors sector.subsectors do |subsector|
    json.(subsector, :id, :name, :x, :y)
  end
end
