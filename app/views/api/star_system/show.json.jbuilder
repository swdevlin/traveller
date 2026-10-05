if @star_system
  json.star_system do
    json.partial! 'api/star_system_detail', star_system: @star_system
  end
else
  json.star_system nil
end

json.parsec do
  json.id @parsec.id
  json.survey_index @parsec.survey_index
end
