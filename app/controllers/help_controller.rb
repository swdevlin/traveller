class HelpController < ApplicationController
  allow_unauthenticated_access

  def index
    @entries = available_pages.sort
    track_view FeatureUsage::HelpMetric::INDEX_PAGE
  end

  def show
    matched = available_pages.find { |p| p == params[:page] }
    return redirect_to(help_path) unless matched

    track_view matched
    render template: "help/#{matched}"
  end

  private

  # Help is public, but only signed-in users' views are counted, which also
  # keeps crawlers out of the numbers. The view must also arrive from a
  # campaign (the help links carry campaign_slug) to be attributed.
  def track_view(page)
    return unless authenticated? && current_campaign.present?

    ahoy.track FeatureUsage::HelpMetric::EVENT, campaign_id: current_campaign.id, page: page
  end

  def available_pages
    Dir.glob(Rails.root.join('app', 'views', 'help', '*.html.erb'))
       .map { |f| File.basename(f, '.html.erb') }
       .reject { |name| name == 'index' || name.start_with?('_') }
  end
end
