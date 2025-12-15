class Sector < ApplicationRecord
  validates :x, :y, presence: true
  has_many :subsectors, dependent: :destroy

  after_create :create_subsectors

  validate :coordinates_unique_with_link

  def wiki_link
    "https://wiki.travellerrpg.com/#{name.tr(' ', '_')}_Sector"
  end

  def traveller_map_url
    "https://travellermap.com/go/#{name.tr(' ', '_')}"
  end

  private

  def coordinates_unique_with_link
    return if x.blank? || y.blank?

    existing = Sector.where(x: x, y: y).where.not(id: id).first
    return unless existing

    safe_name = ERB::Util.h(existing.name)

    path = Rails.application.routes.url_helpers.sector_path(existing)
    message = %(<a href="#{path}">#{safe_name} already exists at #{x}/#{y}.)
    errors.add(:base, message)
  end

  def create_subsectors
    letters = ("A".."P").to_a

    letters.each_with_index do |letter, index|
      x = (index % 4) + 1
      y = (index / 4) + 1

      subsectors.create!(
        x: x,
        y: y,
        abbreviation: letter,
        name: letter
      )
    end

  end
end
