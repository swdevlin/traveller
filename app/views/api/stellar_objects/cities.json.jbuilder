json.count @pagy.count
json.page  @pagy.page
json.pages @pagy.pages
json.cities @cities.each_with_index.map { |city, index| [city, @pagy.from + index] } do |city, position|
  json.partial! 'api/stellar_objects/city', city: city, position: position
end
