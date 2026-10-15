require 'test_helper'

class LanguagesControllerTest < AuthenticatedIntegrationTest
  test 'word returns a JSON word for a valid language' do
    get language_word_url(language: 'aslan')
    assert_response :success
    body = JSON.parse(response.body)
    assert body['word'].present?, 'Expected a word in the response'
  end

  test 'word returns unprocessable entity for an unknown language' do
    get language_word_url(language: 'klingon')
    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert body['error'].present?
  end

  test 'word returns unprocessable entity when language param is missing' do
    get language_word_url
    assert_response :unprocessable_entity
  end

  test 'word generates for a campaign language' do
    get language_word_url(language: 'elvish')
    assert_response :success
    assert JSON.parse(response.body)['word'].present?
  end

  test 'index lists campaign languages' do
    get languages_url
    assert_response :success
    assert_select 'label', text: /Elvish/
    assert_select "a[href='#{edit_language_path(languages(:elvish))}']"
    assert_select 'label', text: /Aslan/
    assert_select "a[href='#{edit_language_path(languages(:elvish))}']", count: 1
  end

  test 'create adds a language' do
    corpus = (1..25).map { |i| "name#{i.to_s.tr('0-9', 'a-j')}" }.join("\n")
    assert_difference('Language.count', 1) do
      post languages_url, params: { language: { name: 'Draconic', corpus: corpus } }
    end
    assert_redirected_to languages_url
  end

  test 'create re-renders with errors for a short word list' do
    assert_no_difference('Language.count') do
      post languages_url, params: { language: { name: 'Draconic', corpus: 'one' } }
    end
    assert_response :unprocessable_entity
  end

  test 'update changes the name' do
    patch language_url(languages(:elvish)), params: { language: { name: 'High Elvish' } }
    assert_redirected_to languages_url
    assert_equal 'High Elvish', languages(:elvish).reload.name
  end

  test 'download returns the word list as text' do
    get download_language_url(languages(:elvish))
    assert_response :success
    assert_match %r{text/plain}, response.content_type
    assert_includes response.body, "aelar\n"
    assert_match(/elvish\.txt/, response.headers['Content-Disposition'])
  end

  test 'create accepts an uploaded word list' do
    file = Tempfile.new(['words', '.txt'])
    file.write((1..25).map { |i| "name#{i.to_s.tr('0-9', 'a-j')}" }.join("\n"))
    file.rewind
    assert_difference('Language.count', 1) do
      post languages_url, params: { language: { name: 'Uploaded', corpus_file: fixture_file_upload(file.path, 'text/plain') } }
    end
  end

  test 'destroy removes an unused language' do
    assert_difference('Language.count', -1) do
      delete language_url(languages(:elvish))
    end
  end

  test 'destroy refuses a language in use' do
    sectors(:one).update!(language: 'elvish')
    assert_no_difference('Language.count') do
      delete language_url(languages(:elvish))
    end
    assert_redirected_to languages_url
  end
end
