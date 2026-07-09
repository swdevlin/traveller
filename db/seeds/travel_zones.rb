[
  { code: 'A', name: 'Amber', colour: '#eab308', protected: true },
  { code: 'R', name: 'Red',   colour: '#dc2626', protected: true }
].each do |attrs|
  TravelZone.find_or_create_by!(code: attrs[:code]) do |tz|
    tz.name      = attrs[:name]
    tz.colour    = attrs[:colour]
    tz.protected = attrs[:protected]
  end
end
