json.id           @parsec.id
json.hex_code     @parsec.hex_code
json.x            @parsec.x
json.y            @parsec.y
json.survey_index @parsec.survey_index

if @star_system
  json.star_system do
    json.partial! 'api/star_system_detail', star_system: @star_system
  end
else
  json.star_system nil
end
