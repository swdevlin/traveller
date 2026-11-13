class RulebookSearchController < ApplicationController
  include TokenAuthenticatable

  optional_authentication only: %i[index more]

  RESULTS_PER_RULEBOOK = 3
  MAX_RESULTS_PER_RULEBOOK = 10
  MORE_RESULTS_PER_RULEBOOK = 100

  VIEWED_EVENT = 'Viewed rule search'
  SEARCHED_EVENT = 'Searched rules'
  EXPANDED_EVENT = 'Expanded rule results'

  before_action :set_noindex

  def index
    @query = params[:q].to_s.strip
    @groups = RulebookSearch.new(
      query: @query,
      referee: referee?,
      rulebook_ids: Array(params[:rulebook_ids]).presence,
      categories: Array(params[:categories]).presence,
      per_rulebook_limit: per_rulebook_limit_param
    ).call
    track_search

    respond_to do |format|
      format.html
      format.json
    end
  end

  def more
    @rulebook = Rulebook.searchable.find(params[:rulebook_id])
    groups = RulebookSearch.new(
      query: params[:q],
      referee: referee?,
      rulebook_ids: [@rulebook.id],
      per_rulebook_limit: MORE_RESULTS_PER_RULEBOOK
    ).call
    @group = groups.first
    track_expansion
  end

  private

  # Opening the search page and running a search are counted separately.
  # The query text is deliberately not stored.
  def track_search
    return if Current.campaign.blank?

    if @query.blank?
      ahoy.track VIEWED_EVENT, campaign_id: Current.campaign.id
    else
      ahoy.track SEARCHED_EVENT,
                 campaign_id: Current.campaign.id,
                 result_count: @groups.sum(&:total_matches),
                 source: authenticated_by_token? ? 'api' : 'web'
    end
  end

  # Fired by the lazy turbo-frame when a rulebook's results are opened and it
  # has more matches than were rendered initially.
  def track_expansion
    return if Current.campaign.blank?

    ahoy.track EXPANDED_EVENT, campaign_id: Current.campaign.id, rulebook_id: @rulebook.id
  end

  def per_rulebook_limit_param
    return RESULTS_PER_RULEBOOK unless params[:per_rulebook_limit].present?

    params[:per_rulebook_limit].to_i.clamp(1, MAX_RESULTS_PER_RULEBOOK)
  end

  def set_noindex
    @noindex = true
  end

  def referee?
    Current.owns_campaign? || authenticated_by_token?
  end
end
