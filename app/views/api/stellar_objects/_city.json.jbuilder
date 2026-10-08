json.name city.name.presence || "City #{position}"
json.type_label city.city_type.present? ? city.type_label : nil
json.capital_label city.capital_label
json.population city.population
