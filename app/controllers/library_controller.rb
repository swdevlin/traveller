class LibraryController < ApplicationController
  def index
    @rulebooks = Rulebook.searchable.order(:title)
    @rulebooks = @rulebooks.where(category: params[:category]) if params[:category].present?
    # Rulebook and CampaignRulebook live on different AR connections (Rulebook
    # is apartment-excluded, pinned to the public schema); a .joins across them
    # would build one SQL statement resolved entirely on one connection, with
    # the same unqualified-table-name risk raw SQL has elsewhere in this
    # feature. Two separate queries merged in Ruby sidesteps that entirely.
    @campaign_rulebooks = CampaignRulebook.where(rulebook_id: @rulebooks.map(&:id)).index_by(&:rulebook_id)
  end

  def toggle_enabled
    campaign_rulebook = CampaignRulebook.find_or_initialize_by(rulebook_id: params[:rulebook_id])
    campaign_rulebook.enabled = !campaign_rulebook.enabled?
    campaign_rulebook.player_searchable = false unless campaign_rulebook.enabled?
    campaign_rulebook.save!
    redirect_to library_path, status: :see_other
  end

  def toggle_player_searchable
    campaign_rulebook = CampaignRulebook.find_or_initialize_by(rulebook_id: params[:rulebook_id])
    campaign_rulebook.player_searchable = !campaign_rulebook.player_searchable?
    campaign_rulebook.enabled = true if campaign_rulebook.player_searchable?
    campaign_rulebook.save!
    redirect_to library_path, status: :see_other
  end
end
