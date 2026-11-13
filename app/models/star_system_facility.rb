class StarSystemFacility < ApplicationRecord
  belongs_to :star_system, touch: true
  belongs_to :facility
end
