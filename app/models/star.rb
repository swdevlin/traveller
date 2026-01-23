class Star < ApplicationRecord
  belongs_to :star_system, optional: true
  belongs_to :parsec, optional: true

  belongs_to :companion, class_name: 'Star', optional: true
  belongs_to :orbiting, class_name: 'Star', optional: true

  has_many :stars,
           foreign_key: :orbiting_id,
           dependent: :destroy

  has_many :stellar_objects,
           foreign_key: :orbiting_star_id,
           inverse_of: :orbiting_star,
           dependent: :destroy

  def spectral_classification
    "#{stellar_type}#{stellar_subtype} #{stellar_class}"
  end

  def orbiting_bodies
    bodies = stellar_objects.to_a + stars.to_a
    bodies.sort_by { |b| b.orbit.to_f }
  end

  def assign_data_from_generator(data)
    self.name = data['name']
    self.orbit_sequence = data['orbitSequence']
    self.orbit = data['orbit']
    self.stellar_class = data['stellarClass']
    self.stellar_type = data['stellarType']
    self.stellar_subtype = data['subtype']
    self.luminosity = data['luminosity']
    self.spread = data['spread']
    self.mass = data['mass']
    self.diameter = data['diameter']
    self.temperature = data['temperature']
    self.age = data['age']
    self.jump_shadow = data['jumpShadow']
    self.colour = data['colour']
    self.is_protostar = data['isProtostar']
    self.minimum_orbit = data['minimumOrbit']
    self.eccentricity = data['eccentricity']
    self.period = data['period']
    self.hzco = data['hzco']
    self.au = data['au']
    self.survey_index = data['surveyIndex']
    self.scan_points = data['scanPoints']
  end
end
