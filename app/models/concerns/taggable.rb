module Taggable
  extend ActiveSupport::Concern

  included do
    has_many :taggings, as: :taggable, dependent: :destroy
    has_many :tags, through: :taggings
  end

  # Alphabetical regardless of load order or the order tags were just assigned in.
  def sorted_tags
    tags.sort_by { [it.name.downcase, it.name] }
  end

  def tag_names
    sorted_tags.map(&:name)
  end

  def tag_list
    tag_names.join(', ')
  end

  def tag_list=(value)
    self.tag_names = value.to_s.split(',')
  end

  def tag_names=(names)
    names = Array(names).map { |name| name.to_s.strip }.reject(&:blank?).uniq
    self.tags = names.map { |name| Tag.find_or_create_by!(name: name) }
  end
end
