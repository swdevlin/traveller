require 'test_helper'

class ApiDocsControllerTest < ActionDispatch::IntegrationTest
  test 'docs page is public' do
    get api_docs_url
    assert_response :success
    assert_includes response.body, api_spec_path
  end

  test 'spec is public and valid yaml' do
    get api_spec_url
    assert_response :success
    spec = YAML.safe_load(response.body)
    assert_match(/\A3\.1/, spec['openapi'])
    assert spec['paths'].key?('/sectors')
  end

  test 'campaign param makes that campaign the first server' do
    get api_spec_url(campaign: 'drizzle')
    assert_response :success
    servers = YAML.safe_load(response.body)['servers']
    assert_equal '/c/drizzle/api', servers.first['url']
    assert_equal '/c/{campaign_slug}/api', servers.second['url']
  end

  test 'docs page passes the campaign on to the spec' do
    get api_docs_url(campaign: 'drizzle')
    assert_includes response.body, 'campaign=drizzle'
  end

  test 'a malformed campaign param is ignored' do
    get api_spec_url(campaign: "x'><script>")
    servers = YAML.safe_load(response.body)['servers']
    assert_equal ['/c/{campaign_slug}/api'], servers.map { |server| server['url'] }
  end

  test 'docs default to the campaign the signed-in user referees' do
    sign_in_as users(:one)

    get api_docs_url

    assert_includes response.body, "campaign=#{campaigns(:one).slug}"
  end

  test 'docs have no default campaign for a visitor who is not signed in' do
    get api_docs_url

    assert_not_includes response.body, 'campaign='
  end

  test 'campaign param overrides the signed-in default' do
    sign_in_as users(:one)

    get api_docs_url(campaign: 'drizzle')

    assert_includes response.body, 'campaign=drizzle'
    assert_not_includes response.body, "campaign=#{campaigns(:one).slug}"
  end
end
