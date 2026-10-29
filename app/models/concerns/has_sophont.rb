# frozen_string_literal: true

# Links a world to its native and extinct Sophonts. The ids live in the jsonb `data` column
# alongside the native_sophont / extinct_sophont flags; they are deliberately not in the
# generator map so regeneration keeps them.
module HasSophont
  extend ActiveSupport::Concern

  included do
    store_accessor :data, :sophont_id, :extinct_sophont_id
    # Defined on the class itself: store_accessor's generated writers would otherwise shadow
    # ones defined in this module. The ids are kept integers so jsonb containment (`@>`) matches.
    define_method(:sophont_id=) { |value| write_store_attribute(:data, :sophont_id, value.presence&.to_i) }
    define_method(:extinct_sophont_id=) { |value| write_store_attribute(:data, :extinct_sophont_id, value.presence&.to_i) }
    # A sophont typed in on the edit form that doesn't exist yet. It is created (named only)
    # with this world's system as its home when the world is saved.
    attr_accessor :new_sophont_name, :new_extinct_sophont_name

    before_save :assign_new_sophont
  end

  def sophont
    Sophont.find_by(id: sophont_id) if sophont_id.present?
  end

  # The extinct sophont, if the world is flagged extinct and one has been recorded. Named
  # `_record` because `extinct_sophont` is the boolean flag.
  def extinct_sophont_record
    Sophont.find_by(id: extinct_sophont_id) if extinct_sophont && extinct_sophont_id.present?
  end

  private

  def assign_new_sophont
    if (found = find_or_create_sophont(new_sophont_name))
      self.sophont_id = found.id
    end
    if (found = find_or_create_sophont(new_extinct_sophont_name))
      self.extinct_sophont_id = found.id
    end
    self.new_sophont_name = self.new_extinct_sophont_name = nil
  end

  def find_or_create_sophont(raw_name)
    name = raw_name.to_s.strip
    return if name.blank?

    Sophont.find_by_name(name) || Sophont.create!(name: name, home_system_id: star_system_id)
  end
end
