# frozen_string_literal: true

class SocialCharacteristicsAssigner
  Result = Struct.new(:errors, keyword_init: true) do
    def success?
      errors.blank?
    end
  end

  SOCIAL_API_FIELDS = {
    'government'   => :government=,
    'lawLevel'     => :law_level=,
    'techLevel'    => :tech_level_code=,
    'starport'     => :starport_code=
  }.freeze

  def initialize(star_system, generator_service)
    @star_system = star_system
    @generator_service = generator_service
  end

  def assign(params)
    payload = StarSystemGeneratorSerializer.new(@star_system).serialize
    payload['government'] = params[:government_code].to_i if params[:government_code].present?
    payload['lawLevel']   = params[:law_level_code].to_i  if params[:law_level_code].present?
    payload['population'] = population_payload(params[:population])
    tl = range_payload(params[:tech_level])
    payload['techLevel'] = tl if tl
    payload['starport'] = params[:starport_code] if params[:starport_code].present?
    payload['mainWorldCriteria'] = params[:main_world_criteria] if params[:main_world_criteria].present?
    payload['allowCaptiveGovernment'] = true if params[:allow_captive_government] == '1'

    result = @generator_service.assign_social_characteristics(payload)
    return Result.new(errors: result.errors) unless result.success?

    apply_result(result.value, params[:allegiance_id])
    Result.new(errors: [])
  end

  private

  def population_payload(population_params)
    min_val = population_params&.dig(:min).presence
    max_val = population_params&.dig(:max).presence
    return { 'min' => 1 } if min_val.nil? && max_val.nil?

    {}.tap do |h|
      h['min'] = min_val.to_i if min_val
      h['max'] = max_val.to_i if max_val
    end
  end

  def range_payload(range_params)
    min_val = range_params&.dig(:min).presence
    max_val = range_params&.dig(:max).presence
    return nil if min_val.nil? && max_val.nil?

    {}.tap do |h|
      h['min'] = min_val.to_i if min_val
      h['max'] = max_val.to_i if max_val
    end
  end

  def apply_result(data, allegiance_id = nil)
    world_data = data['world']
    return if world_data.blank?

    orbit_sequence = world_data['orbitSequence']
    so = @star_system.stellar_objects.find_by(orbit_sequence: orbit_sequence)
    return unless so&.respond_to?(:government_code)

    ActiveRecord::Base.transaction do
      so.allegiance_id = allegiance_id if allegiance_id.present?
      update_social_fields(so, world_data)
      update_trade_codes(so, world_data['tradeCodes'])
      star_system_attrs = { main_world: so }
      star_system_attrs[:allegiance_id] = allegiance_id if allegiance_id.present?
      @star_system.update!(star_system_attrs)
    end
  end

  def update_trade_codes(so, codes)
    StellarObjectTradeCode.where(stellar_object: so).delete_all
    StarSystemTradeCode.where(star_system: @star_system).delete_all

    return if codes.blank?

    codes.uniq.each do |code|
      trade_code = TradeCode.find_by(code: code)
      next unless trade_code

      StellarObjectTradeCode.create!(stellar_object: so, trade_code: trade_code)
      StarSystemTradeCode.create!(star_system: @star_system, trade_code: trade_code)
    end
  end

  def update_social_fields(so, data)
    SOCIAL_API_FIELDS.each do |api_key, setter|
      next unless data.key?(api_key)
      value = data[api_key]
      if api_key == 'techLevel'
        tech_level = GeneratorMappings.build_tech_level_from_generator(value)
        so.data ||= {}
        so.data['tech_level'] = tech_level
        value = tech_level['code']
      end
      so.public_send(setter, value)
    end
    so.population = data['population'] if data.key?('population')
    so.uwp = data['uwp'] if data.key?('uwp')
    so.save!
  end
end
