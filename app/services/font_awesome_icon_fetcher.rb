# frozen_string_literal: true

# app/services/font_awesome_icon_fetcher.rb
require 'net/http'
require 'json'
require 'cgi'

class FontAwesomeIconFetcher
  API_URL = 'https://api.fontawesome.com'
  ICON_NAME = /\Afa-[a-z0-9-]+\z/
  STYLE = /\A[a-z-]+\z/

  class Error < StandardError; end
  class NotFound < Error; end

  def self.call(name, style: 'regular', version: '7.x')
    new(name:, style:, version:).call
  end

  def initialize(name:, style: 'regular', version: '7.x')
    @name = name.to_s.strip
    @style = style.to_s.strip
    @version = version
  end

  def call
    validate!

    icon_name = @name.delete_prefix('fa-')

    response = post_graphql(icon_name)
    svg = extract_svg(response, icon_name)

    {
      name: @name,
      style: @style,
      view_box: "0 0 #{svg.fetch('width')} #{svg.fetch('height')}",
      svg_content: paths_for(svg.fetch('pathData'))
    }
  end

  private

  def validate!
    raise ArgumentError, 'invalid Font Awesome icon name' unless @name.match?(ICON_NAME)
    raise ArgumentError, 'invalid Font Awesome style' unless @style.match?(STYLE)
  end

  def post_graphql(icon_name)
    uri = URI(API_URL)

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{access_token}"

    request.body = {
      query: query,
      variables: {
        version: @version,
        icon: icon_name,
        style: @style.upcase
      }
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    raise Error, "Font Awesome returned HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end

  def query
    <<~GRAPHQL
      query Icon($version: String!, $icon: String!, $style: Style!) {
        release(version: $version) {
          icon(name: $icon) {
            id
            svgs(filter: { familyStyles: [{ family: CLASSIC, style: $style }] }) {
              width
              height
              pathData
              familyStyle {
                family
                style
                prefix
              }
            }
          }
        }
      }
    GRAPHQL
  end

  def extract_svg(response, icon_name)
    errors = response['errors']
    raise Error, errors.map { |e| e['message'] }.join(', ') if errors.present?

    icon = response.dig('data', 'release', 'icon')
    raise NotFound, "Font Awesome icon not found: fa-#{icon_name}" unless icon

    svg = icon.fetch('svgs').first
    raise NotFound, "Font Awesome icon style not found: fa-#{icon_name} #{@style}" unless svg

    svg
  end

  def paths_for(path_data)
    path_data.map do |path|
      %(<path d="#{CGI.escapeHTML(path)}" />)
    end.join
  end

  def access_token
    uri = URI("#{API_URL}/token")
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{ENV.fetch('FONT_AWESOME_TOKEN')}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    raise Error, 'Font Awesome token exchange failed' unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).fetch('access_token')
  end
end
