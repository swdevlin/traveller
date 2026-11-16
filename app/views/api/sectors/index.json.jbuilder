json.array! @sectors do |sector|
  json.(sector, :id, :name, :x, :y, :abbreviation)
  json.partial! 'api/records', record: sector, html: false
  # Unlike other endpoints, the key is always present here; it is null without referee access.
  json.classified_records nil unless Current.referee_access?
  json.subsectors sector.subsectors do |subsector|
    json.(subsector, :id, :name, :x, :y)
  end
end
