# frozen_string_literal: true

namespace :star_systems do
  desc 'Print the starmap detail JSON for a star system. Use CAMPAIGN=slug ID=123 [REFEREE=0] [HOST=example.com]'
  task :json, [:campaign, :id] => :environment do |_task, args|
    slug = (args[:campaign] || ENV['CAMPAIGN']).presence or abort 'Specify a campaign with CAMPAIGN=slug'
    id = (args[:id] || ENV['ID']).presence or abort 'Specify a star system with ID=123'
    campaign = Campaign.find_by(slug: slug) or abort "No campaign found with slug '#{slug}'"

    Apartment::Tenant.switch(campaign.schema_name) do
      star_system = StarSystem
                    .includes({ parsec: { sector: :subsectors } }, :allegiance, :facilities,
                              { stars: [{ stellar_objects: [{ moons: %i[allegiance orbiting] }, :allegiance, :orbiting] }, :companion,
                                        { stars: [{ stellar_objects: [{ moons: %i[allegiance orbiting] }, :allegiance, :orbiting] }, :companion] }] },
                              main_world: :trade_codes)
                    .find_by(id: id) or abort "No star system with id #{id} in campaign '#{slug}'"

      Current.campaign = campaign

      renderer = Api::StarSystemController.renderer.new(
        http_host: ENV.fetch('HOST', 'localhost:3000'),
        'action_dispatch.request.path_parameters' => { campaign_slug: slug }
      )
      json = renderer.render(
        template: 'api/star_system/show',
        formats: [:json],
        assigns: {
          star_system: star_system,
          parsec: star_system.parsec,
          is_referee: ENV['REFEREE'] != '0'
        }
      )

      puts JSON.pretty_generate(JSON.parse(json))
    end
  end
end
