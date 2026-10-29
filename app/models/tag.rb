# Tags belong to the current campaign's tenant, like the objects that use them.
class Tag < ApplicationRecord
  OBJECT_TYPES = %w[Sector Subsector StarSystem StellarObject Region].freeze

  # Second Survey nobility codes, as found in the Traveller Map Nobility column.
  NOBILITY = {
    'B' => 'Knight',
    'c' => 'Baronet',
    'C' => 'Baron',
    'D' => 'Marquis',
    'e' => 'Viscount',
    'E' => 'Count',
    'f' => 'Duke',
    'F' => 'Subsector Duke',
    'G' => 'Archduke',
    'H' => 'Emperor'
  }.freeze

  has_many :taggings, dependent: :destroy

  normalizes :name, with: -> { it.to_s.strip }
  normalizes :description, with: -> { it.presence }

  validates :name, presence: true, uniqueness: true
  validates :name, format: { without: /,/, message: 'cannot contain commas' }

  scope :alphabetical, -> { order(Arel.sql('lower(tags.name)'), :name) }

  # Adds any nobility tag not already present in the current tenant. Safe to repeat.
  def self.seed_nobility
    NOBILITY.each do |code, title|
      find_or_create_by!(name: title) { it.description = "Imperial noble rank (Second Survey code #{code})" }
    end
  end

  def self.nobility_names(codes)
    Array(codes).filter_map { NOBILITY[it] }
  end

  def self.names
    alphabetical.pluck(:name)
  end

  # Tag names assigned directly to the given records of one type.
  def self.names_for(type, ids)
    joins(:taggings).where(taggings: { taggable_type: type, taggable_id: ids }).distinct.pluck(:name)
  end

  # { record_id => [names] } for the given records of one type.
  def self.names_by_record(type, ids)
    joins(:taggings).where(taggings: { taggable_type: type, taggable_id: ids })
                    .alphabetical.pluck('taggings.taggable_id', :name)
                    .group_by(&:first).transform_values { |rows| rows.map(&:last) }
  end

  def counts
    by_type = taggings.group(:taggable_type).count
    OBJECT_TYPES.to_h { |type| [type.constantize.model_name.human.pluralize, by_type.fetch(type, 0)] }
  end

  def usage_count
    taggings.count
  end

  # Renaming onto an existing tag merges the two; returns the surviving tag.
  def rename!(replacement)
    replacement = replacement.to_s.strip
    raise ArgumentError, 'Enter a tag name without commas.' if replacement.blank? || replacement.include?(',')

    transaction do
      existing = self.class.where.not(id: id).find_by(name: replacement)
      if existing
        merge_into!(existing)
        existing
      else
        update!(name: replacement)
        self
      end
    end
  end

  private

  def merge_into!(other)
    taggings.find_each do |tagging|
      if other.taggings.exists?(taggable_type: tagging.taggable_type, taggable_id: tagging.taggable_id)
        tagging.destroy!
      else
        tagging.update!(tag: other)
      end
    end
    destroy!
  end
end
