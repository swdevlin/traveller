class RenameSurveyIndexToDefaultSiInSubsectorBuild < ActiveRecord::Migration[8.1]
  def up
    Subsector.where.not(build: nil).find_each do |subsector|
      config = safe_load(subsector.build)
      next unless config.is_a?(Hash)
      next unless config.key?('surveyIndex') && !config.key?('defaultSI')

      config['defaultSI'] = config.delete('surveyIndex')
      subsector.update_columns(build: YAML.dump(config))
    end
  end

  # Irreversible: after `up`, a row with a top-level `defaultSI` and no `surveyIndex`
  # is indistinguishable from a row that legitimately had `defaultSI` all along (e.g.
  # Deepnight imports set it directly — see Subsector#apply_deepnight_defaults!). There's
  # no reliable way to tell "always correct" apart from "just fixed", so a safe rollback
  # isn't possible.
  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def safe_load(yaml_text)
    YAML.safe_load(yaml_text, permitted_classes: [], permitted_symbols: [], aliases: false)
  rescue Psych::SyntaxError
    nil
  end
end
