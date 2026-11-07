class AccountDeletionsController < ApplicationController
  def new
    @user = Current.user
  end

  def destroy
    user = Current.user

    unless user.authenticate(params.dig(:user, :password))
      user.errors.add(:password, 'is incorrect')
      @user = user
      return render :new, status: :unprocessable_entity
    end

    user.update!(email_address: "deleted-#{user.id}-#{SecureRandom.hex(8)}@deleted.invalid",
                 password: SecureRandom.hex(32))
    user.sessions.destroy_all
    cookies.delete(:session_id)
    DeleteAccountJob.set(priority: 100).perform_later(user.id)

    # A literal path, not root_path: default_url_options would otherwise carry
    # this request's campaign_slug (for a campaign that's about to be dropped)
    # onto the redirect target.
    redirect_to '/', notice: 'Your account is being deleted.'
  end
end
