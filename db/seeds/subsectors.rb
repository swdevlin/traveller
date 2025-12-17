# frozen_string_literal: true

letters = ("A".."P").to_a

Sector.find_each do |sector|
  letters.each_with_index do |letter, index|
    x = (index % 4) + 1
    y = (index / 4) + 1

    subsector = sector.subsectors.find_or_initialize_by(sector: sector, x: x, y: y)

    subsector.name = "#{sector.name} #{letter}"
    subsector.abbreviation = "#{sector.abbreviation}-#{letter}"
    subsector.save
  end
end
