class RulebookPage < ApplicationRecord
  belongs_to :rulebook

  validates :pdf_page_number, presence: true, uniqueness: { scope: :rulebook_id }
  validates :printed_page_number_override, numericality: { only_integer: true }, allow_nil: true
  validate :not_both_overridden_and_unnumbered

  def effective_printed_page_number
    return nil if printed_page_unnumbered?

    # page_number_offset is defined as (pdf page - printed page), so it's subtracted here to
    # recover the printed page: e.g. pdf page 18 showing "17" printed has offset 1, and
    # 18 - 1 = 17.
    printed_page_number_override || (pdf_page_number - rulebook.page_number_offset)
  end

  def effective_printed_page_label
    printed_page_unnumbered? ? 'Unnumbered page' : effective_printed_page_number.to_s
  end

  private

  def not_both_overridden_and_unnumbered
    return unless printed_page_unnumbered? && printed_page_number_override.present?

    errors.add(:base, 'cannot both override the printed page number and mark it unnumbered')
  end
end
