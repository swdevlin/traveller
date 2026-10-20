# frozen_string_literal: true

# Links a world to its native Sophont. The id lives in the jsonb `data` column alongside the
# native_sophont flag; it is deliberately not in the generator map so regeneration keeps it.
module HasSophont
  extend ActiveSupport::Concern

  included do
    store_accessor :data, :sophont_id
    # Defined on the class itself: store_accessor's generated writer would otherwise shadow
    # one defined in this module. The id is kept an integer so jsonb containment (`@>`) matches.
    define_method(:sophont_id=) { |value| write_store_attribute(:data, :sophont_id, value.presence&.to_i) }
    # A sophont typed in on the edit form that doesn't exist yet. It is created (named only)
    # with this world's system as its home when the world is saved.
    attr_accessor :new_sophont_name

    before_save :assign_new_sophont
  end

  def sophont
    Sophont.find_by(id: sophont_id) if sophont_id.present?
  end

  private

  def assign_new_sophont
    name = new_sophont_name.to_s.strip
    return if name.blank?

    found = Sophont.find_by_name(name) || Sophont.create!(name: name, home_system_id: star_system_id)
    self.sophont_id = found.id
    self.new_sophont_name = nil
  end
end
