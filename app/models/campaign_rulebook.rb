class CampaignRulebook < ApplicationRecord
  belongs_to :rulebook

  validates :rulebook_id, presence: true, uniqueness: true
  validate :player_searchable_requires_enabled

  scope :enabled, -> { where(enabled: true) }
  scope :player_searchable, -> { where(player_searchable: true) }

  private

  def player_searchable_requires_enabled
    return unless player_searchable? && !enabled?

    errors.add(:player_searchable, 'cannot be set unless the rulebook is enabled for this campaign')
  end
end
