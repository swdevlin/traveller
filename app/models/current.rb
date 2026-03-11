class Current < ActiveSupport::CurrentAttributes
  attribute :session, :campaign
  delegate :user, to: :session, allow_nil: true
end
