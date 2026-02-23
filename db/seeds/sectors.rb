# frozen_string_literal: true

sectors = [
  {
    x: -5, y: -1, name: 'Foreven', abbreviation: 'Fore',
    subsector_names: [
      'Shivva', 'Lieber', 'Shial', 'Massina',
      'Pieplow', 'Anika', 'Mowbrey', 'Fessor',
      'Lassana', 'Xenough Titan', 'Xenough', 'Reidain',
      'Rull', 'Harem', 'Piah', 'Urnian'
    ]
  }
]

sectors.each do |attrs|
  puts(".#{attrs[:name]}")

  sector = Sector.find_or_initialize_by(x: attrs[:x], y: attrs[:y])
  is_new = sector.new_record?
  sector.name = attrs[:name]
  sector.abbreviation = attrs[:abbreviation]

  if is_new
    Sector.skip_callback(:commit, :after, :create_subsectors_and_parsecs)
    begin
      sector.save!
    ensure
      Sector.set_callback(:commit, :after, :create_subsectors_and_parsecs)
    end

    (attrs[:subsector_names] || []).each_with_index do |name, index|
      letter = ('A'.ord + index).chr
      x = (index % 4) + 1
      y = (index / 4) + 1
      CreateSubsectorJob.perform_now(sector.id, letter, x, y, name)
    end
  else
    sector.save!

    (attrs[:subsector_names] || []).each_with_index do |name, index|
      x = (index % 4) + 1
      y = (index / 4) + 1
      sector.subsectors.find_by(x: x, y: y)&.update!(name: name)
    end
  end
end
