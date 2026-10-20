# Runs once per tenant schema. Only charted space campaigns get the default sophonts; the
# public schema and other campaign types are skipped. Existing sophonts are never duplicated.
class SeedDefaultSophontsForChartedSpaceCampaigns < ActiveRecord::Migration[8.1]
  DEFAULTS = {
    'Aslan' => 'aslan', 'Solomani' => 'solomani', 'Vargr' => 'arrghoun', 'Zhodani' => 'zdetl',
    "K'Kree" => nil, 'Darrian' => nil, 'Hiver' => nil, 'Vegan' => nil, 'Droyne' => 'oynprith',
    'Vilani' => 'imperium', 'Geonee' => nil, 'Suerrat' => nil, 'Dolphin' => nil, 'Orca' => nil,
    'Bwap' => nil, 'Za’tachk' => nil, 'Gurvin' => 'gurvin', 'Tezcat' => nil
  }.freeze

  def up
    return unless charted_space_tenant?

    DEFAULTS.each do |name, language|
      execute <<~SQL.squish
        INSERT INTO sophonts (name, language, created_at, updated_at)
        SELECT #{quote(name)}, NULLIF(#{quote(language.to_s)}, ''), now(), now()
        WHERE NOT EXISTS (SELECT 1 FROM sophonts WHERE lower(name) = #{quote(name.downcase)})
      SQL
    end
  end

  def down
    # Sophonts may since have been edited or assigned to worlds, so nothing is removed.
  end

  private

  def charted_space_tenant?
    Campaign.exists?(schema_name: Apartment::Tenant.current, campaign_type: 'charted_space')
  end
end
