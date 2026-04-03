# frozen_string_literal: true

class StarSystemGeneratorSerializer
  def initialize(star_system)
    @star_system = star_system
  end

  def serialize
    {
      'system' => { 'primaryStar' => serialize_star(@star_system.primary_star) }
    }
  end

  private

  def serialize_star(star)
    result = object_attributes(star)
    result['stellarObjects'] = []
    star.stars.order(:orbit).each do |companion|
      result['stellarObjects'] << serialize_star(companion)
    end
    star.stellar_objects.order(:orbit).each do |so|
      result['stellarObjects'] << serialize_stellar_object(so)
    end
    result
  end

  def serialize_stellar_object(so)
    result = object_attributes(so)
    if so.respond_to?(:moons)
      result['moons'] = so.moons.map { |m| object_attributes(m) }
    end
    result
  end

  def object_attributes(obj)
    result = {
      'orbitSequence' => obj.orbit_sequence,
      'orbit' => obj.orbit,
      'au' => obj.au,
      'orbitType' => obj.respond_to?(:orbit_type) ? obj.orbit_type : nil,
      'name' => obj.name,
      'surveyIndex' => obj.survey_index,
      'uwp' => obj.uwp
    }
    result['size'] = obj.size_code if obj.respond_to?(:size_code)

    if obj.class.respond_to?(:generator_api_data_map) && obj.data.present?
      api_map = obj.class.generator_api_data_map
      obj.data.each do |attr_key, value|
        api_key = api_map[attr_key]
        result[api_key] = value if api_key
      end
    end

    result.compact
  end
end
