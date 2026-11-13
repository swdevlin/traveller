class Admin::MetricsController < AdminController
  WINDOWS = {
    '7d' => { label: '7 days', duration: 7.days },
    '30d' => { label: '30 days', duration: 30.days },
    'all' => { label: 'All time', duration: nil }
  }.freeze
  DEFAULT_WINDOW = '30d'

  def show
    @windows = WINDOWS
    @window = WINDOWS.key?(params[:window]) ? params[:window] : DEFAULT_WINDOW
    @metrics = FeatureUsage::Catalogue.all(since: WINDOWS.dig(@window, :duration)&.ago)
  end
end
