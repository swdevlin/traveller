# frozen_string_literal: true

class RulebookSearch
  ExcerptSegment = Struct.new(:text, :highlighted, keyword_init: true)
  Hit            = Struct.new(:rulebook_page, :rank, :heading_segments, :excerpt_segments, keyword_init: true)
  Group          = Struct.new(:rulebook, :total_matches, :relevant_matches, :hits, :low_relevance_hits, keyword_init: true)

  TOTAL_ROW_LIMIT       = 200
  DEFAULT_RULEBOOK_CAP  = 20
  DEFAULT_PER_RULEBOOK  = 3
  SEGMENT_START = "\u0001"
  SEGMENT_STOP  = "\u0002"

  # ts_rank_cd default weights are {D: 0.1, C: 0.2, B: 0.4, A: 1.0}. Halving the body
  # ('B') weight to 0.2 gives heading ('A') matches more relative pull without the
  # extreme cut (down around 0.05) that would be needed to make a single heading match
  # always beat heavy body-text repetition outright. The 'C' zone holds item/stat-block
  # lines (see TextNormalizer::ITEM_LINE_PATTERN) and the 'D' zone holds bold text (see
  # TextNormalizer::MARKDOWN_BOLD) — both set to 1.0, matching the heading ('A') weight,
  # since Postgres caps ts_rank_cd weights at 1.0, the maximum possible pull for either
  # zone. An item's stat-block entry or an author's own emphasis are both treated as
  # significant a match as a heading hit; each is also still counted once at body weight,
  # since neither is removed from normalized_body, so a single item-line or bold match
  # (1.0 + 0.2) ties a single heading-only match on equal footing.
  RANK_WEIGHTS = '{1.0,1.0,0.2,1.0}'

  # Relevance floor, operator-configurable via ENV. Cuts off weak, incidental
  # matches on a common word.
  MINIMUM_RANK = ENV.fetch('RULEBOOK_SEARCH_MINIMUM_RANK', '0.1').to_f

  # Bar for a match to count as "relevant" rather than merely fetched.
  # Operator-configurable via ENV, same pattern as MINIMUM_RANK. Matches at
  # or above this rank are shown by default; matches between MINIMUM_RANK
  # and this threshold are fetched but hidden behind the "include
  # low-relevance matches" toggle.
  RELEVANT_RANK_THRESHOLD = ENV.fetch('RULEBOOK_SEARCH_RELEVANT_RANK', '1.0').to_f

  def initialize(query:, referee:, rulebook_ids: nil, categories: nil,
                 per_rulebook_limit: DEFAULT_PER_RULEBOOK, rulebook_cap: DEFAULT_RULEBOOK_CAP)
    @query = query.to_s.strip
    @referee = referee
    # A <select> with nothing chosen submits an empty string, not an absent
    # param — Array("").presence is [""] (non-empty), not nil, so blank
    # entries must be rejected before checking presence or an empty-string
    # filter value ends up bound against a bigint column.
    @rulebook_ids = Array(rulebook_ids).reject(&:blank?).presence
    @categories = Array(categories).reject(&:blank?).presence
    @per_rulebook_limit = per_rulebook_limit
    @rulebook_cap = rulebook_cap
  end

  def call
    return [] if @query.blank?

    rows = execute_query
    rows.group_by { |row| row['rulebook_id'] }
        .values
        .sort_by { |group_rows| -group_rows.first['rank'].to_f }
        .first(@rulebook_cap)
        .map { |group_rows| build_group(group_rows) }
  end

  private

  # Conditions/params are built together as named (`:foo`) bind variables via
  # ActiveRecord::Base.sanitize_sql_array, so @query can appear multiple times
  # in the SQL (match predicate, rank, headline) and optional IN (...) filters
  # can be added or omitted independently, all without manually tracking
  # positional $1/$2/$3 placeholder numbers.
  #
  # `rulebooks`/`rulebook_pages` are explicitly schema-qualified as `public.*`.
  # Rulebook/RulebookPage are apartment-excluded models, permanently pinned to
  # their own connection on the public schema — but this query runs on the
  # *shared*, tenant-switched connection (ActiveRecord::Base.connection), and
  # every campaign schema has its own empty shadow copy of these two tables
  # (created by the same migrations that created the real ones in public).
  # An unqualified reference would silently resolve to that empty copy
  # whenever this runs inside a campaign-scoped (tenant-switched) request,
  # returning zero rows with no error. `campaign_rulebooks` is the opposite:
  # it's an ordinary per-tenant table with no public-schema data of its own,
  # so it must stay unqualified to resolve against whichever campaign schema
  # is currently active.
  def execute_query
    conditions = [
      'public.rulebooks.searchable = true',
      "public.rulebooks.status = 'ready'",
      'campaign_rulebooks.enabled = true',
      'public.rulebook_pages.search_vector @@ websearch_to_tsquery(:dictionary, :query)',
      # Can't reference the `rank` SELECT-list alias here — Postgres doesn't allow
      # that in WHERE — so the ts_rank_cd + rank_modifier expression is repeated.
      "(ts_rank_cd('#{RANK_WEIGHTS}', public.rulebook_pages.search_vector, websearch_to_tsquery(:dictionary, :query)) " \
      '+ public.rulebooks.rank_modifier) >= :minimum_rank'
    ]
    conditions << 'campaign_rulebooks.player_searchable = true' unless @referee

    params = { dictionary: 'english', query: @query, minimum_rank: MINIMUM_RANK, relevant_threshold: RELEVANT_RANK_THRESHOLD }

    if @rulebook_ids
      conditions << 'public.rulebooks.id IN (:rulebook_ids)'
      params[:rulebook_ids] = @rulebook_ids
    end

    if @categories
      conditions << 'public.rulebooks.category IN (:categories)'
      params[:categories] = @categories
    end

    sql = <<~SQL
      SELECT sub.*,
             COUNT(*) OVER (PARTITION BY sub.rulebook_id) AS total_matches,
             COUNT(*) FILTER (WHERE sub.rank >= :relevant_threshold) OVER (PARTITION BY sub.rulebook_id) AS relevant_matches
      FROM (
        SELECT public.rulebook_pages.id, public.rulebook_pages.rulebook_id, public.rulebook_pages.pdf_page_number,
               public.rulebook_pages.printed_page_number_override, public.rulebook_pages.printed_page_unnumbered,
               public.rulebooks.title, public.rulebooks.short_title, public.rulebooks.edition, public.rulebooks.category,
               public.rulebooks.page_number_offset,
               ts_rank_cd('#{RANK_WEIGHTS}', public.rulebook_pages.search_vector, websearch_to_tsquery(:dictionary, :query))
                 + public.rulebooks.rank_modifier AS rank,
               ts_headline(:dictionary, COALESCE(public.rulebook_pages.heading, ''), websearch_to_tsquery(:dictionary, :query),
                           'StartSel=#{SEGMENT_START}, StopSel=#{SEGMENT_STOP}, MaxFragments=1, MaxWords=20, MinWords=1') AS heading_headline,
               ts_headline(:dictionary, public.rulebook_pages.normalized_body, websearch_to_tsquery(:dictionary, :query),
                           'StartSel=#{SEGMENT_START}, StopSel=#{SEGMENT_STOP}, MaxFragments=1, MaxWords=35, MinWords=15') AS headline
        FROM public.rulebook_pages
        JOIN public.rulebooks ON public.rulebooks.id = public.rulebook_pages.rulebook_id
        JOIN campaign_rulebooks ON campaign_rulebooks.rulebook_id = public.rulebooks.id
        WHERE #{conditions.join(' AND ')}
      ) sub
      ORDER BY sub.rank DESC
      LIMIT #{TOTAL_ROW_LIMIT}
    SQL

    sanitized = ActiveRecord::Base.sanitize_sql_array([sql, params])
    ActiveRecord::Base.connection.exec_query(sanitized, 'RulebookSearch')
  end

  def build_group(rows)
    first = rows.first
    rulebook = Rulebook.new(
      id: first['rulebook_id'],
      title: first['title'],
      short_title: first['short_title'],
      edition: first['edition'],
      category: first['category'],
      page_number_offset: first['page_number_offset']
    )

    # `rows` arrives ORDER BY rank DESC from execute_query; #partition
    # preserves that order in both resulting arrays.
    relevant_rows, low_relevance_rows = rows.partition { |row| row['rank'].to_f >= RELEVANT_RANK_THRESHOLD }

    Group.new(
      rulebook: rulebook,
      total_matches: first['total_matches'].to_i,
      relevant_matches: first['relevant_matches'].to_i,
      hits: relevant_rows.first(@per_rulebook_limit).map { |row| build_hit(row, rulebook) },
      low_relevance_hits: low_relevance_rows.first(@per_rulebook_limit).map { |row| build_hit(row, rulebook) }
    )
  end

  def build_hit(row, rulebook)
    page = RulebookPage.new(
      pdf_page_number: row['pdf_page_number'],
      printed_page_number_override: row['printed_page_number_override'],
      printed_page_unnumbered: row['printed_page_unnumbered']
    )
    page.rulebook = rulebook

    Hit.new(rulebook_page: page, rank: row['rank'].to_f,
            heading_segments: split_headline(row['heading_headline']), excerpt_segments: split_headline(row['headline']))
  end

  def split_headline(headline)
    headline.to_s.split(/(#{SEGMENT_START}.*?#{SEGMENT_STOP})/m).reject(&:empty?).map do |chunk|
      if chunk.start_with?(SEGMENT_START)
        ExcerptSegment.new(text: chunk.delete_prefix(SEGMENT_START).delete_suffix(SEGMENT_STOP), highlighted: true)
      else
        ExcerptSegment.new(text: chunk, highlighted: false)
      end
    end
  end
end
