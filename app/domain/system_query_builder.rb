# Translates the same rule_data shape used by `SurveyOverlay` (see
# `HasFilterRule`) into real SQL predicates so it can be paginated at scale,
# instead of `SurveyOverlay#matches?`'s per-record Ruby evaluation (built for
# colouring an already-fetched batch of map hexes, not filtering a whole
# campaign).
class SystemQueryBuilder
  UWP_JSON_FIELDS = %w[atmosphere hydrographics population government law_level tech_level].freeze
  RANKED_TEXT_FIELDS = %w[size starport].freeze

  def initialize(rule_data)
    rule_data ||= {}
    @groups = (rule_data['groups'] || rule_data[:groups] || []).map do |group|
      group.map { |condition| condition.symbolize_keys }
    end
  end

  # A rule with no groups matches everything here — unlike
  # `SurveyOverlay#matches?`, where `[].any?` makes an empty rule match
  # nothing. That's the right default for an overlay (nothing to highlight
  # yet), but the wrong one for a query meant to browse/report on a
  # campaign — a freshly created, still-empty query should just list every
  # system rather than none.
  def relation(base_scope = StarSystem.all)
    return base_scope if @groups.empty?

    @groups.map { |group| group_relation(group, base_scope) }.reduce { |combined, rel| combined.or(rel) }
  end

  private

  def group_relation(conditions, base_scope)
    conditions.reduce(base_scope) { |scope, condition| apply_condition(scope, condition) }
  end

  def apply_condition(scope, condition)
    field = condition[:field]
    operator = condition[:operator]
    values = condition[:values] || []

    matching_ids = field_relation(field, operator, values).select('star_systems.id')

    condition[:negate] ? scope.where.not(id: matching_ids) : scope.where(id: matching_ids)
  end

  # `field` is request-controlled (see `SystemQuery`), so this dispatch is the security
  # boundary for every `column` string built below: each branch must resolve to a
  # hardcoded literal (or, for `uwp_json_relation`, a value passed through `quote`),
  # never `field`/`values` interpolated directly. That invariant is why the raw-SQL
  # `where("#{column} ...")` calls in `numeric_predicate`/`boolean_column_relation`/
  # `ranked_text_relation` are safe despite Brakeman flagging them (see
  # `config/brakeman.ignore`) — don't break it when adding a field.
  def field_relation(field, operator, values)
    case field
    when *UWP_JSON_FIELDS then uwp_json_relation(field, operator, values)
    when *RANKED_TEXT_FIELDS then ranked_text_relation(field, operator, values)
    when 'survey_index' then integer_column_relation('star_systems.survey_index', operator, values)
    when 'gas_giant_count' then integer_column_relation('star_systems.gas_giant_count', operator, values)
    when 'planetoid_belt_count' then integer_column_relation('star_systems.belt_count', operator, values)
    when 'known' then boolean_column_relation('star_systems.known', values)
    when 'native_sophont' then boolean_column_relation('star_systems.native_sophont', values)
    when 'extinct_sophont' then boolean_column_relation('star_systems.extinct_sophont', values)
    when 'importance' then importance_relation(operator, values)
    when 'base_count' then base_count_relation(operator, values)
    when 'star_count' then star_count_relation(operator, values)
    when 'primary_star' then primary_star_relation(operator, values)
    when 'primary_star_class' then primary_star_class_relation(operator, values)
    when 'bases' then bases_relation(values)
    when 'allegiance' then allegiance_relation(values)
    when 'sector' then sector_relation(values)
    when 'subsector' then subsector_relation(values)
    else StarSystem.none
    end
  end

  # atmosphere/hydrographics/population/government/law_level/tech_level are
  # stored as a plain integer `code` inside `stellar_objects.data`
  # (`HasUwp#atmosphere_code=` etc. always `.to_i`s the value) — the rule's
  # values are hex-alphabet characters (`HasFilterRule::FIELD_OPTIONS`), so
  # convert them to their integer equivalent before comparing.
  def uwp_json_relation(field, operator, values)
    column = "(main_worlds.data -> #{quote(field)} ->> 'code')::integer"
    numeric_values = values.map { |v| HexDigit::HEX_DIGITS.index(v) }
    numeric_predicate(join_main_world(StarSystem.all), column, operator, numeric_values)
  end

  # `size` (a plain `size_code` string column) and `starport`
  # (`stellar_objects.data->>'starport_code'`) hold the character itself, not
  # an integer — `eq`/`one_of` compare the character directly, ranked
  # comparisons go through a CASE expression giving each valid character its
  # `HasFilterRule::FIELD_OPTIONS` rank (reversed for starport, since A is
  # best — mirrors `SurveyOverlay#field_rank`).
  def ranked_text_relation(field, operator, values)
    column = field == 'size' ? 'main_worlds.size_code' : "main_worlds.data ->> 'starport_code'"
    scope = join_main_world(StarSystem.all)

    case operator
    when 'eq' then scope.where("#{column} = ?", values.first)
    when 'one_of' then scope.where("#{column} IN (?)", values)
    else
      numeric_predicate(scope, rank_case_sql(column, field), operator, values.map { |v| rank_of(field, v) })
    end
  end

  def rank_of(field, code)
    options = HasFilterRule::FIELD_OPTIONS.fetch(field).map(&:first)
    index = options.index(code)
    field == 'starport' ? options.size - 1 - index : index
  end

  def rank_case_sql(column, field)
    options = HasFilterRule::FIELD_OPTIONS.fetch(field).map(&:first)
    ranked = field == 'starport' ? options.reverse : options
    whens = ranked.each_with_index.map { |code, rank| "WHEN #{quote(code)} THEN #{rank}" }.join(' ')
    "(CASE #{column} #{whens} END)"
  end

  def importance_relation(operator, values)
    column = "(main_worlds.data -> 'economics' ->> 'importance')::integer"
    numeric_predicate(join_main_world(StarSystem.all), column, operator, values.map(&:to_i))
  end

  def base_count_relation(operator, values)
    column = '(SELECT COUNT(*) FROM star_system_facilities ' \
             'WHERE star_system_facilities.star_system_id = star_systems.id)'
    numeric_predicate(StarSystem.all, column, operator, values.map(&:to_i))
  end

  def star_count_relation(operator, values)
    column = '(SELECT COUNT(*) FROM stellar_objects ' \
             "WHERE stellar_objects.star_system_id = star_systems.id AND stellar_objects.type = 'Star')"
    numeric_predicate(StarSystem.all, column, operator, values.map(&:to_i))
  end

  # `stellar_type` is a plain code (like `starport`/`size`) rather than a
  # ranked one — normal spectral types, brown dwarf letters and the special
  # types (black hole, nebula, etc.) have no single meaningful ordering — so
  # only `eq`/`one_of` are supported, enforced by `OPERATORS_FOR_FIELD`.
  def primary_star_relation(operator, values)
    scope = join_primary_star(StarSystem.all)

    case operator
    when 'eq' then scope.where("primary_stars.data ->> 'stellar_type' = ?", values.first)
    when 'one_of' then scope.where("primary_stars.data ->> 'stellar_type' IN (?)", values)
    else StarSystem.none
    end
  end

  # `stellar_class` (luminosity) IS meaningfully ordered — most to least
  # luminous, per `HasFilterRule::FIELD_OPTIONS['primary_star_class']` — so
  # ranked comparisons rank on that list's position, ascending (no
  # `starport`-style reversal).
  def primary_star_class_relation(operator, values)
    scope = join_primary_star(StarSystem.all)
    column = "primary_stars.data ->> 'stellar_class'"
    options = HasFilterRule::FIELD_OPTIONS.fetch('primary_star_class').map(&:first)

    case operator
    when 'eq' then scope.where("#{column} = ?", values.first)
    when 'one_of' then scope.where("#{column} IN (?)", values)
    else
      whens = options.each_with_index.map { |code, rank| "WHEN #{quote(code)} THEN #{rank}" }.join(' ')
      numeric_predicate(scope, "(CASE #{column} #{whens} END)", operator, values.map { |v| options.index(v) })
    end
  end

  # `has` and `has_one_of` both mean "has at least one facility whose code is
  # in `values`" — a single-value `has` condition is just the one-element
  # case of that same set membership check.
  def bases_relation(values)
    StarSystem.where(id: StarSystemFacility.joins(:facility).where(facilities: { code: values }).select(:star_system_id))
  end

  def allegiance_relation(values)
    StarSystem.where(allegiance_id: Allegiance.where(code: values).select(:id))
  end

  def sector_relation(values)
    StarSystem.joins(:parsec).where(parsecs: { sector_id: values })
  end

  # Subsector has no foreign key to Parsec — it's geometric (`Parsec#subsector`
  # computes it from x/y against `Sector#upper_left`). Resolve each target
  # subsector to its parsec x/y bounding box and OR the ranges together.
  def subsector_relation(values)
    subsectors = Subsector.where(id: values).includes(:sector)
    return StarSystem.none if subsectors.empty?

    parsec_scope = subsectors.map { |subsector| parsec_bounding_box(subsector) }
                              .reduce { |a, b| a.or(b) }

    StarSystem.where(parsec_id: parsec_scope.select(:id))
  end

  def parsec_bounding_box(subsector)
    ul = subsector.sector.upper_left
    x_min = ul.x + (subsector.x - 1) * 8
    x_max = x_min + 7
    y_max = ul.y - (subsector.y - 1) * 10
    y_min = y_max - 9

    Parsec.where(sector_id: subsector.sector_id, x: x_min..x_max, y: y_min..y_max)
  end

  def integer_column_relation(column, operator, values)
    numeric_predicate(StarSystem.all, column, operator, values.map(&:to_i))
  end

  def boolean_column_relation(column, values)
    StarSystem.where("#{column} = ?", values.first == 'true')
  end

  def join_main_world(scope)
    scope.joins('INNER JOIN stellar_objects main_worlds ON main_worlds.id = star_systems.main_world_id')
  end

  def join_primary_star(scope)
    scope.joins(
      'INNER JOIN stellar_objects primary_stars ON primary_stars.star_system_id = star_systems.id ' \
      "AND primary_stars.type = 'Star' AND primary_stars.orbiting_id IS NULL"
    )
  end

  def numeric_predicate(scope, column, operator, numeric_values)
    case operator
    when 'eq' then scope.where("#{column} = ?", numeric_values.first)
    when 'one_of' then scope.where("#{column} IN (?)", numeric_values)
    when 'lt' then scope.where("#{column} < ?", numeric_values.first)
    when 'lte' then scope.where("#{column} <= ?", numeric_values.first)
    when 'gt' then scope.where("#{column} > ?", numeric_values.first)
    when 'gte' then scope.where("#{column} >= ?", numeric_values.first)
    when 'between'
      lo, hi = numeric_values.minmax
      scope.where("#{column} BETWEEN ? AND ?", lo, hi)
    else
      scope.none
    end
  end

  def quote(value)
    ActiveRecord::Base.connection.quote(value)
  end
end
