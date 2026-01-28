# db/seeds.rb

puts "Seeding trade codes..."
require_relative "seeds/trade_codes"

puts "Seeding sectors..."
require_relative "seeds/sectors"

puts "Seeding bases..."
require_relative "seeds/facilities"

puts "Seeding law levels..."
require_relative "seeds/law_levels"

puts "Seeding governments..."
require_relative "seeds/governments"
