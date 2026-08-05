require 'test_helper'

class Admin::RulebooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @rulebook = rulebooks(:core)
  end

  teardown do
    # Tests that only assert a job was enqueued (not that it ran) leave their
    # staged upload behind, since cleanup happens inside the job itself.
    FileUtils.rm_rf(Rails.root.join('tmp', 'rulebook_uploads'))
  end

  test 'a logged-out request is 404, not a redirect' do
    get admin_rulebooks_url
    assert_response :not_found
  end

  test 'a logged-in, non-admin request is 404' do
    sign_in_as users(:one)
    get admin_rulebooks_url
    assert_response :not_found
  end

  test 'an admin can view the index' do
    sign_in_as users(:admin)
    get admin_rulebooks_url
    assert_response :success
  end

  test 'an admin can view a rulebook' do
    sign_in_as users(:admin)
    get admin_rulebook_url(@rulebook)
    assert_response :success
  end

  test 'an admin can reach the edit form for a rulebook, including one just created' do
    sign_in_as users(:admin)
    file = Rack::Test::UploadedFile.new(file_fixture('sample_rulebook.pdf'), 'application/pdf')

    post admin_rulebooks_url, params: { rulebook: { title: 'Freshly Created', category: 'rulebook', page_number_offset: 0, pdf_file: file } }
    rulebook = Rulebook.order(:created_at).last

    get edit_admin_rulebook_url(rulebook)
    assert_response :success
    assert_includes @response.body, 'Freshly Created'
  end

  test 'an admin can create a rulebook, translating header/footer patterns from the textarea' do
    sign_in_as users(:admin)
    file = Rack::Test::UploadedFile.new(file_fixture('sample_rulebook.pdf'), 'application/pdf')

    assert_difference('Rulebook.count') do
      post admin_rulebooks_url, params: {
        rulebook: {
          title: 'New Sourcebook', category: 'supplement', page_number_offset: 0,
          header_footer_patterns_raw: "foo\nbar\n\n", pdf_file: file
        }
      }
    end

    rulebook = Rulebook.order(:created_at).last
    assert_redirected_to admin_rulebook_url(rulebook)
    assert_equal %w[foo bar], rulebook.header_footer_patterns
  end

  test 'creating a rulebook enqueues a backfill of existing campaigns' do
    sign_in_as users(:admin)
    file = Rack::Test::UploadedFile.new(file_fixture('sample_rulebook.pdf'), 'application/pdf')

    assert_enqueued_with(job: BackfillCampaignRulebookJob) do
      post admin_rulebooks_url, params: {
        rulebook: { title: 'Backfill Me', category: 'rulebook', page_number_offset: 0, pdf_file: file }
      }
    end
  end

  test 'rejects creation without a PDF' do
    sign_in_as users(:admin)

    assert_no_difference('Rulebook.count') do
      post admin_rulebooks_url, params: { rulebook: { title: 'No File', category: 'rulebook', page_number_offset: 0 } }
    end

    assert_response :unprocessable_entity
    assert_includes @response.body, 'A PDF file is required to create a rulebook.'
  end

  test 'rejects creation with a non-PDF file' do
    sign_in_as users(:admin)
    file = Rack::Test::UploadedFile.new(StringIO.new('not a pdf'), 'text/plain', original_filename: 'notes.txt')

    assert_no_difference('Rulebook.count') do
      post admin_rulebooks_url, params: { rulebook: { title: 'Bad File', category: 'rulebook', page_number_offset: 0, pdf_file: file } }
    end

    assert_response :unprocessable_entity
  end

  test 'an admin can update a rulebook' do
    sign_in_as users(:admin)
    patch admin_rulebook_url(@rulebook), params: { rulebook: { title: 'Renamed Core Rulebook' } }
    assert_redirected_to admin_rulebook_url(@rulebook)
    assert_equal 'Renamed Core Rulebook', @rulebook.reload.title
  end

  test 'an admin can destroy a rulebook' do
    sign_in_as users(:admin)
    assert_difference('Rulebook.count', -1) do
      delete admin_rulebook_url(@rulebook)
    end
  end

  test 'triggering an import enqueues ImportRulebookJob with force: true against a staged copy' do
    sign_in_as users(:admin)
    file = Rack::Test::UploadedFile.new(file_fixture('sample_rulebook.pdf'), 'application/pdf')

    assert_enqueued_jobs 1, only: ImportRulebookJob do
      post import_admin_rulebook_url(@rulebook), params: { pdf_file: file }
    end

    job_args = enqueued_jobs.last[:args]
    assert_equal @rulebook.id, job_args[0]
    assert_match %r{tmp/rulebook_uploads/#{@rulebook.id}-[0-9a-f]+\.pdf\z}, job_args[1]
    # Always force: true — an upload is always reprocessed, even if byte-identical to what's
    # already imported, rather than silently no-opping on a matching checksum.
    assert job_args[2]['force']
    assert job_args[2]['cleanup_after']
    assert_redirected_to admin_rulebook_url(@rulebook)
  end

  test 'rejects import without a PDF' do
    sign_in_as users(:admin)
    post import_admin_rulebook_url(@rulebook)
    assert_redirected_to admin_rulebook_url(@rulebook)
    follow_redirect!
    assert_includes @response.body, 'Please upload a PDF file.'
  end

  test 'rebuilding search vectors enqueues RebuildRulebookSearchVectorsJob' do
    sign_in_as users(:admin)
    assert_enqueued_with(job: RebuildRulebookSearchVectorsJob, args: [@rulebook.id]) do
      post rebuild_search_vectors_admin_rulebook_url(@rulebook)
    end
  end

  test 'toggling searchable flips the flag' do
    sign_in_as users(:admin)
    assert @rulebook.searchable?

    patch toggle_searchable_admin_rulebook_url(@rulebook)
    assert_not @rulebook.reload.searchable?
  end

  test 'never renders the server-local staged upload path back to the admin' do
    sign_in_as users(:admin)
    file = Rack::Test::UploadedFile.new(file_fixture('sample_rulebook.pdf'), 'application/pdf')

    post import_admin_rulebook_url(@rulebook), params: { pdf_file: file }
    follow_redirect!

    assert_not @response.body.include?(Rails.root.join('tmp', 'rulebook_uploads').to_s)
  end
end
