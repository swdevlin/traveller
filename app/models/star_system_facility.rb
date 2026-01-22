class StarSystemFacility < ApplicationRecord
  belongs_to :star_system
  belongs_to :facility
end
