class Sector < ApplicationRecord
  include ClearableParsecs
  validates :x, :y, presence: true
  has_many :subsectors, dependent: :destroy
  has_many :parsecs, dependent: :destroy

  after_create :create_subsectors_and_parsecs

  validate :coordinates_unique_with_link


  def wiki_link
    "https://wiki.travellerrpg.com/#{name.tr(' ', '_')}_Sector"
  end

  def traveller_map_url
    "https://travellermap.com/go/#{name.tr(' ', '+')}"
  end

  def universal_coordinates
    ul = Coordinate.new(x*32, y*40)
    lr = ul.clone
    lr.x += 31
    lr.y -= 39

    [ul, lr]
  end

  def upper_left
    Coordinate.new(x*32, y*40)
  end

  def hexes
    ul, lr = universal_coordinates
    Parsec.where(x: ul.x..lr.x, y: lr.y..ul.y)
  end

  def neighbours
    Sector
        .where(x: (x-1..x+1), y: (y-1..y+1))
        .index_by { |s| [s.x, s.y] }
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

  def create_subsectors_and_parsecs
    return if Rails.env.test?
    create_subsectors
    create_parsecs
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

  def create_parsecs
    ul, lr = universal_coordinates
    (0...32).each do |x|
      (0...40).each do |y|
        parsecs.create!(
          x: ul.x + x,
          y: ul.y - y
        )
      end
    end
  end
end
