class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :campaigns, foreign_key: :referee_id, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 8 }, on: :create

  PASSWORD_RESET_EXPIRES_IN = 15.minutes

  generates_token_for :password_reset, expires_in: PASSWORD_RESET_EXPIRES_IN do
    password_salt&.last(10)
  end

  def password_reset_token_expires_in
    self.class::PASSWORD_RESET_EXPIRES_IN
  end
end
