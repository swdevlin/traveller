class Tagging < ApplicationRecord
  belongs_to :tag
  belongs_to :taggable, polymorphic: true

  validates :tag_id, uniqueness: { scope: %i[taggable_type taggable_id] }
end
