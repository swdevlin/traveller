require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  include ApplicationHelper

  test 'current_theme_light? is true for a light theme' do
    cookies[:theme] = 'light'
    assert current_theme_light?
  end

  test 'current_theme_light? is false for a dark theme' do
    cookies[:theme] = 'vargr'
    assert_not current_theme_light?
  end

  test 'current_theme_light? defaults to false when no theme cookie is set' do
    assert_not current_theme_light?
  end
end
