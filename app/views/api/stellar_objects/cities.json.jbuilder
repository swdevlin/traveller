json.count @pagy.count
json.page  @pagy.page
json.pages @pagy.pages
json.cities @cities.map.with_index(@pagy.from) { |city, position|
  {
    name: city.name.presence || "City #{position}",
    type_label: city.city_type.present? ? city.type_label : nil,
    capital_label: city.capital_label,
    population: city.population
  }
}
