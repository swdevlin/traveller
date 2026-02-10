# frozen_string_literal: true

class GeneratorService
  Result = Struct.new(:value, :errors, keyword_init: true) do
    def success?
      errors.blank?
    end
  end

  def generate_star_system(definition)
    call_service('star_system', definition)
  end

  def generate_subsector(definition)
    call_service('subsector', definition)
  end

  private

  def base_url
    Rails.application.config.x.generator_service
  end

  def call_service(endpoint, data)
    uri = URI.join(base_url.end_with?('/') ? base_url : "#{base_url}/", endpoint)

    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 50
    http.read_timeout = 50

    headers = {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }

    response = http.post(uri.request_uri, data.to_json, headers)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "#{uri} Failure: HTTP #{response.code} - #{response.body}"
      return Result.new(errors: ['Cannot create star system at this time'])
    end

    begin
      parsed = JSON.parse(response.body)
      Result.new(value: parsed)
    rescue JSON::ParserError => e
      Rails.logger.error "#{uri} JSON Error: #{e.message} - Body: #{response.body}"
      Result.new(errors: ['Cannot create star system at this time'])
    end
  end
end
