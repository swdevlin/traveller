require 'test_helper'

class Admin::RulebookPagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @rulebook = rulebooks(:core)
    @page = rulebook_pages(:core_page_starships)
  end

  test 'a logged-out request is 404' do
    get mapping_admin_rulebook_rulebook_pages_url(@rulebook)
    assert_response :not_found
  end

  test 'a non-admin request is 404' do
    sign_in_as users(:one)
    get mapping_admin_rulebook_rulebook_pages_url(@rulebook)
    assert_response :not_found
  end

  test 'an admin sees the page-mapping table with default and effective printed pages' do
    sign_in_as users(:admin)
    get mapping_admin_rulebook_rulebook_pages_url(@rulebook)

    assert_response :success
    assert_includes @response.body, 'PDF Page'
    assert_includes @response.body, @page.heading
  end

  test 'an admin can view a single page' do
    sign_in_as users(:admin)
    get admin_rulebook_rulebook_page_url(@rulebook, @page)
    assert_response :success
    assert_includes @response.body, @page.body
  end

  test 'an admin can set a printed page override' do
    sign_in_as users(:admin)
    patch admin_rulebook_rulebook_page_url(@rulebook, @page), params: { rulebook_page: { printed_page_number_override: 7 } }

    assert_redirected_to admin_rulebook_rulebook_page_url(@rulebook, @page)
    assert_equal 7, @page.reload.printed_page_number_override
  end

  test 'an admin can mark a page unnumbered' do
    sign_in_as users(:admin)
    patch admin_rulebook_rulebook_page_url(@rulebook, @page), params: { rulebook_page: { printed_page_unnumbered: true } }

    assert @page.reload.printed_page_unnumbered?
  end

  test 'rejects setting both an override and unnumbered with a friendly form error, not a raw DB exception' do
    sign_in_as users(:admin)
    patch admin_rulebook_rulebook_page_url(@rulebook, @page),
          params: { rulebook_page: { printed_page_number_override: 7, printed_page_unnumbered: true } }

    assert_response :unprocessable_entity
    assert_includes @response.body, 'cannot both override the printed page number and mark it unnumbered'
  end

  test 'never leaks the server-local PDF path in the page-mapping table' do
    sign_in_as users(:admin)
    get mapping_admin_rulebook_rulebook_pages_url(@rulebook)
    assert_not @response.body.include?('/private/')
  end
end
