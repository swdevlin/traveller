require 'test_helper'

class HandoutPaletteTest < ActiveSupport::TestCase
  WHITE = HandoutPalette::WHITE

  test 'every theme gives an accent that is readable on white' do
    OrbitMapTheme::PALETTES.each_key do |theme|
      accent = HandoutPalette.parse(HandoutPalette.for(theme)[:accent])

      assert_operator HandoutPalette.contrast(accent, WHITE), :>=, HandoutPalette::MIN_CONTRAST, theme
    end
  end

  test 'a theme whose highlight is already dark keeps it' do
    assert_equal '#2563eb', OrbitMapTheme.palette('darrian').highlight
    palette = HandoutPalette.for('darrian')

    assert_operator HandoutPalette.contrast(HandoutPalette.parse(palette[:accent]), WHITE), :>=, 4.8
    assert_match(/\A#[0-9a-f]{6}\z/, palette[:tint])
  end

  test 'a bright highlight is darkened rather than used as it is' do
    assert_not_equal OrbitMapTheme.palette('vargr').highlight, HandoutPalette.for('vargr')[:accent]
  end

  test 'tints are lighter than the accent and an unknown theme falls back' do
    palette = HandoutPalette.for('no-such-theme')

    assert_equal HandoutPalette.for('dark'), palette
    assert_operator HandoutPalette.luminance(HandoutPalette.parse(palette[:tint])),
                    :>, HandoutPalette.luminance(HandoutPalette.parse(palette[:rule]))
  end
end
