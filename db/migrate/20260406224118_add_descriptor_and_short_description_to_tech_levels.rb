class AddDescriptorAndShortDescriptionToTechLevels < ActiveRecord::Migration[8.1]
  def up
    add_column :tech_levels, :descriptor, :string
    add_column :tech_levels, :short_description, :text

    data = {
      0  => ['Primitive',       'Stone Age. No formal tools beyond the most primitive.'],
      1  => ['Primitive',       'Bronze and iron age. Primitive metalworking and weapons.'],
      2  => ['Primitive',       'Renaissance. Scientific method, early chemistry and astronomy.'],
      3  => ['Primitive',       'Steam age. Industrial revolution beginning, primitive firearms.'],
      4  => ['Industrial',      'Early industrial. Plastics, radio, internal combustion.'],
      5  => ['Industrial',      'Electrification. Telecommunications, early atomics and computing.'],
      6  => ['Industrial',      'Fission age. Nuclear power and advanced computing. Dawn of spaceflight.'],
      7  => ['Pre-Stellar',     'Early space age. Reliable orbital access, satellites, integrated circuits.'],
      8  => ['Pre-Stellar',     'Interplanetary. Other worlds reachable; fusion power commercially viable.'],
      9  => ['Pre-Stellar',     'Jump age. Gravity control and jump drive. Interstellar colonisation possible.'],
      10 => ['Early Stellar',   'Interstellar. Jump drives common; interstellar trade and colonisation boom.'],
      11 => ['Early Stellar',   'AI age. First true artificial intelligence; Jump-2 drives.'],
      12 => ['Average Stellar', 'Climate control. Planetary weather control; Jump-3 drives.'],
      13 => ['Average Stellar', 'Battle dress. Cloned body parts; Jump-4 drives.'],
      14 => ['Average Stellar', 'Flying cities. Portable fusion weapons; Jump-5 drives.'],
      15 => ['High Stellar',    'Black globes. Synthetic anagathics extend human lifespan indefinitely.'],
      16 => ['High Stellar',    'Transcendent. Technologies beyond the standard stellar classification.']
    }

    data.each do |code, (descriptor, short_description)|
      TechLevel.where(code: code).update_all(descriptor: descriptor, short_description: short_description)
    end
  end

  def down
    remove_column :tech_levels, :descriptor
    remove_column :tech_levels, :short_description
  end
end
