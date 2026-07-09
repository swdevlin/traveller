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
end
