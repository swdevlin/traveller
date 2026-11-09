# frozen_string_literal: true

require 'test_helper'

class StarmapsControllerTest < AuthenticatedIntegrationTest
  def starmap_flags
    node = css_select('#root').first
    JSON.parse(node['data-starmap-flags'])
  end

  test 'flags carry the campaign jump log display defaults' do
    campaigns(:one).update!(jump_log_display: 'both', jump_log_line_style: 'dashed', jump_log_line_width: 6)

    # The all-sectors raster is irrelevant here (and slow to build); point it at any existing file.
    generator = Struct.new(:output_path, :call).new(Rails.root.join('Gemfile'), nil)
    stub_new(AllSectorsMapGenerator, generator) do
      get campaign_starmap_url
    end

    assert_response :success
    display = starmap_flags['jumpLogDisplay']

    assert_equal 'both', display['display']
    assert_equal '#ffedd5', display['fillColour']
    assert_equal '#f97316', display['lineColour']
    assert_equal 'dashed', display['lineStyle']
    assert_equal 6, display['lineWidth']
    assert_equal '16,10', display['lineDasharray']
  end
end
