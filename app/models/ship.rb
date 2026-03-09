class Ship < ApplicationRecord
  has_many :jump_logs, dependent: :destroy

  def to_s
    name
  end
end
