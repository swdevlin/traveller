json.array! @sectors do |sector|
  json.(sector, :id, :name, :x, :y, :abbreviation)
  json.partial! 'api/records', record: sector, html: false
  json.subsectors sector.subsectors do |subsector|
    json.(subsector, :x, :y, :name)
    json.partial! 'api/records', record: subsector, html: false
  end
end
