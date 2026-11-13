# Base for the panels on the admin metrics page. A metric fetches its own
# data and names the partial that renders it, so the page just does
# `render @metrics` and a new kind of metric needs a subclass and a partial,
# with no change to the page or controller.
class FeatureUsage::Metric
  class << self
    # Marks a base class that shouldn't appear on the page itself.
    def abstract!
      @abstract = true
    end

    def abstract?
      @abstract == true
    end
  end

  attr_reader :since

  def initialize(since: nil)
    @since = since
  end

  def title
    raise NotImplementedError, "#{self.class} must define title"
  end

  def to_partial_path
    raise NotImplementedError, "#{self.class} must define to_partial_path"
  end

  # { column_key => count } for the dashboard's headline tiles; metrics that
  # have no headline numbers return nothing.
  def totals
    {}
  end
end
