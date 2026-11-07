require 'test_helper'

class AccountDeletionsControllerTest < AuthenticatedIntegrationTest
  test 'new renders the confirmation form' do
    get new_account_deletion_url

    assert_response :success
  end

  test 'wrong password is rejected, shown beside the field, and the account survives' do
    assert_no_enqueued_jobs do
      delete account_deletion_url, params: { user: { password: 'wrong' } }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, 'Password is incorrect'
    assert_equal 'one@example.com', users(:one).reload.email_address
  end

  test 'correct password scrambles credentials, kills sessions, and enqueues deletion' do
    user = users(:one)

    assert_enqueued_with(job: DeleteAccountJob, args: [user.id]) do
      delete account_deletion_url, params: { user: { password: 'password' } }
    end

    assert_redirected_to '/'

    user.reload
    assert_match(/\Adeleted-#{user.id}-.+@deleted\.invalid\z/, user.email_address)
    assert_not user.authenticate('password')
    assert_equal 0, user.sessions.count
    assert cookies['session_id'].blank?
  end
end
