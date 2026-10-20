# frozen_string_literal: true

module HasReferenceUrl
  extend ActiveSupport::Concern

  def effective_reference_url(campaign)
    reference_url.presence || derived_reference_url(campaign)
  end

  def derived_reference_url(campaign)
    campaign&.charted_space? ? default_reference_url : nil
  end

  private

  def default_reference_url
    nil
  end
end
