# frozen_string_literal: true

module UrlHelper
  # Returns a safe URL string or nil.
  # Only allows http/https absolute URLs.
  def safe_external_url(url)
    return nil if url.blank?

    uri = URI.parse(url.to_s)
    return nil unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

    uri.to_s
  rescue URI::InvalidURIError
    nil
  end
end
# frozen_string_literal: true

