json.array! @sectors do |sector|
  json.(sector, :id, :name, :x, :y, :abbreviation)
end
