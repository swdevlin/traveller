# frozen_string_literal: true

# Fetches a planet's JSON through the API view, posts it to the planetmap service and writes the SVG.
#
#   MAP_SERVICE_URL=http://192.168.1.230:3013 bin/rails runner script/check_planet_map.rb [id] [seed] [out.svg]
#
# Rails renders the same JSON as /c/<slug>/stellar_objects/<id>.json, inside the campaign's tenant,
# so no login or API token is needed.
id = (ARGV[0] || 1_586_535).to_i
seed = ARGV[1] || 'check'
out = ARGV[2] || Rails.root.join('tmp', "planet_#{id}.svg").to_s
slug = ENV.fetch('CAMPAIGN_SLUG', 'charted')

campaign = Campaign.find_by!(slug: slug)
Apartment::Tenant.switch(campaign.schema_name) do
  Current.campaign = campaign
  controller = Api::StellarObjectsController.new
  controller.request = ActionDispatch::TestRequest.create(
    'HTTP_HOST' => 'localhost:3000', 'REQUEST_METHOD' => 'GET',
    'PATH_INFO' => "/c/#{slug}/api/stellar_objects/#{id}",
    'action_dispatch.request.path_parameters' => { campaign_slug: slug, id: id.to_s, controller: 'api/stellar_objects', action: 'show' }
  )
  controller.request.format = :json
  controller.response = ActionDispatch::TestResponse.new
  controller.params = ActionController::Parameters.new(campaign_slug: slug, id: id.to_s)
  controller.send(:set_current_campaign)
  controller.process(:show)

  planet = JSON.parse(controller.response.body)
  puts "Request body (#{planet.class}, size_code=#{planet['size_code'].inspect}):"
  puts JSON.pretty_generate(planet).lines.first(8).join + '  ...'

  begin
    rendered = MapService.new.render(planet, seed: seed)
    File.write(out, rendered.svg)
    puts "OK: wrote #{rendered.svg.bytesize} bytes to #{out} (seed used: #{rendered.seed})"
  rescue MapService::Error => e
    puts "FAILED: #{e.message}"
    exit 1
  end
end
