class RulebookSearchController < ApplicationController
  optional_authentication only: %i[index more]

  RESULTS_PER_RULEBOOK = 3
  MAX_RESULTS_PER_RULEBOOK = 10
  MORE_RESULTS_PER_RULEBOOK = 100

  before_action :set_noindex

  def index
    @query = params[:q].to_s.strip
    @groups = RulebookSearch.new(
      query: @query,
      referee: Current.user.present?,
      rulebook_ids: Array(params[:rulebook_ids]).presence,
      editions: Array(params[:editions]).presence,
      categories: Array(params[:categories]).presence,
      per_rulebook_limit: per_rulebook_limit_param
    ).call

    respond_to do |format|
      format.html
      format.json
    end
  end

  def more
    @rulebook = Rulebook.searchable.find(params[:rulebook_id])
    groups = RulebookSearch.new(
      query: params[:q],
      referee: Current.user.present?,
      rulebook_ids: [@rulebook.id],
      per_rulebook_limit: MORE_RESULTS_PER_RULEBOOK
    ).call
    @group = groups.first
  end

  private

  def per_rulebook_limit_param
    return RESULTS_PER_RULEBOOK unless params[:per_rulebook_limit].present?

    params[:per_rulebook_limit].to_i.clamp(1, MAX_RESULTS_PER_RULEBOOK)
  end

  def set_noindex
    @noindex = true
  end
end
