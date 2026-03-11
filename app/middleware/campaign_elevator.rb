# frozen_string_literal: true

class CampaignElevator < Apartment::Elevators::Generic
  private

  def parse_tenant_name(request)
    match = request.path.match(%r{\A/c/(?<slug>[^/]+)})
    return nil unless match

    Campaign.find_by(slug: match[:slug])&.schema_name
  end
end
