# frozen_string_literal: true

module ScrubsMailtoLinks
  extend ActiveSupport::Concern

  included do
    before_validation :scrub_mailto_links
  end

  private

  def scrub_mailto_links
    %i[player_notes referee_notes].each do |attribute|
      value = self[attribute]
      self[attribute] = scrub_mailto_from_markdown(value) if value.present?
    end
  end

  def scrub_mailto_from_markdown(text)
    t = text.to_s

    # [label](mailto:someone@example.com)  -> label
    t = t.gsub(/\[([^\]]+)\]\(\s*mailto:[^)]+\)/i, '\1')

    # <mailto:someone@example.com> -> someone@example.com
    t = t.gsub(/<\s*mailto:([^>\s]+)\s*>/i, '\1')

    # autolink: mailto:someone@example.com -> someone@example.com
    t.gsub(/\bmailto:([^\s)>\]]+)/i, '\1')
  end
end
