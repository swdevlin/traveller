require 'test_helper'

class DeleteAccountJobTest < ActiveJob::TestCase
  test 'destroys the user and every campaign they referee, dropping each tenant schema' do
    user = User.create!(email_address: "delete-me-#{SecureRandom.hex(4)}@example.com", password: 'password123')
    campaign = Campaign.create!(name: 'Doomed', slug: "camp-#{SecureRandom.hex(4)}", referee: user, campaign_type: 'homebrew')
    schema_name = campaign.schema_name

    DeleteAccountJob.perform_now(user.id)

    assert_not User.exists?(user.id)
    assert_not Campaign.exists?(campaign.id)
    assert_not schema_exists?(schema_name)
  end

  test 'is a no-op when the user is already gone' do
    assert_nothing_raised do
      DeleteAccountJob.perform_now(-1)
    end
  end

  private

  def schema_exists?(schema_name)
    quoted = ActiveRecord::Base.connection.quote(schema_name)
    ActiveRecord::Base.connection.select_value("SELECT 1 FROM information_schema.schemata WHERE schema_name = #{quoted}").present?
  end
end
