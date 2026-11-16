class Rulebook < ApplicationRecord
  has_many :rulebook_pages, dependent: :destroy

  enum :status, {
    pending: 'pending',
    processing: 'processing',
    ready: 'ready',
    failed: 'failed'
  }, validate: true

  enum :category, {
    rulebook: 'rulebook',
    supplement: 'supplement',
    adventure: 'adventure',
    setting: 'setting',
    alien_module: 'alien_module',
    other: 'other'
  }, validate: true, prefix: true

  validates :title, presence: true
  validates :page_number_offset, numericality: { only_integer: true }
  validates :rank_modifier, numericality: true
  validate :header_footer_patterns_are_valid_regexes

  scope :searchable, -> { where(searchable: true, status: 'ready') }

  after_commit :broadcast_update

  # Rulebooks the current campaign has enabled, matching what RulebookSearch can
  # reach: players only see those the referee has made player searchable.
  # Rulebook is apartment-excluded while CampaignRulebook is per-tenant, so this
  # is two queries rather than a join.
  def self.available_to_campaign(referee:)
    enabled = CampaignRulebook.enabled
    enabled = enabled.player_searchable unless referee
    searchable.where(id: enabled.select(:rulebook_id).to_a.map(&:rulebook_id)).order(:title)
  end

  def to_s
    short_title.presence || title
  end

  private

  # Fires on every create/update/destroy, including each status transition an import job makes
  # (pending -> processing -> ready/failed), so the admin rulebooks index and the campaign
  # Library page can refresh themselves without a manual reload.
  def broadcast_update
    ActionCable.server.broadcast('ui_updates', { event: 'rulebook_updated', at: Time.current.iso8601 })
  end

  def header_footer_patterns_are_valid_regexes
    Array(header_footer_patterns).each do |pattern|
      Regexp.new(pattern)
    rescue RegexpError
      errors.add(:header_footer_patterns, "contains an invalid pattern: #{pattern}")
    end
  end
end
