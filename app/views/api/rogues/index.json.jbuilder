json.array! @rogues do |rogue|
  json.type           rogue.type
  json.name           rogue.name.to_s
  json.x              rogue.parsec.x
  json.y              rogue.parsec.y
  json.survey_index   rogue.parsec.survey_index
  json.known          rogue.known
  json.player_visible rogue.parsec.player_visible

  case rogue
  when Comet
    json.comet_type rogue.comet_type
  when GasGiant
    json.code     rogue.code
    json.diameter rogue.diameter
    json.mass     rogue.mass
  end
end
