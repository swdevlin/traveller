# frozen_string_literal: true

# The theme colours used by the orbit map. The Elm map styles itself with CSS variables
# (--color-outline etc.), which only resolve inside a page carrying a data-theme. The Rails
# map is also served standalone and rasterised to webp, so the resolved values are baked
# in here instead. Values are copied from the theme blocks in app/assets/tailwind/application.css.
module OrbitMapTheme
  DEFAULT = 'dark'

  Palette = Struct.new(:outline, :highlight, :fg_muted, :panel, keyword_init: true)

  PALETTES = {
    'dark' => Palette.new(outline: '#334155', highlight: '#e10600', fg_muted: '#94a3b8', panel: '#0f172a'),
    'light' => Palette.new(outline: '#cbd5e1', highlight: '#c81e1e', fg_muted: '#64748b', panel: '#ffffff'),
    'aslan' => Palette.new(outline: '#8a4b1f', highlight: '#f59e0b', fg_muted: '#c9a46a', panel: '#2a1308'),
    'bwap' => Palette.new(outline: '#8bbfba', highlight: '#8a4f1d', fg_muted: '#5f7f86', panel: '#f4ffff'),
    'darrian' => Palette.new(outline: '#93c5fd', highlight: '#2563eb', fg_muted: '#64748b', panel: '#ffffff'),
    'deepnight' => Palette.new(outline: '#9aa2a9', highlight: '#dc6818', fg_muted: '#687078', panel: '#f7f8f9'),
    'droyne' => Palette.new(outline: '#3a6f7d', highlight: '#a7f3d0', fg_muted: '#9fc7d8', panel: '#10242b'),
    'hiver' => Palette.new(outline: '#5f7f3a', highlight: '#d9f99d', fg_muted: '#a7c58f', panel: '#1e2a13'),
    'imperium' => Palette.new(outline: '#53627a', highlight: '#d8bd72', fg_muted: '#a8b3c4', panel: '#1a2740'),
    'kkree' => Palette.new(outline: '#c7cfb4', highlight: '#8b9a46', fg_muted: '#7c7a68', panel: '#fffdf6'),
    'solomani' => Palette.new(outline: '#5f6a67', highlight: '#d85a50', fg_muted: '#9ca49d', panel: '#222a2b'),
    'swordworlds' => Palette.new(outline: '#59636f', highlight: '#79d6f0', fg_muted: '#98a3b4', panel: '#232831'),
    'vargr' => Palette.new(outline: '#7e22ce', highlight: '#00f5d4', fg_muted: '#d8b4fe', panel: '#240046'),
    'vegan' => Palette.new(outline: '#2563eb', highlight: '#7dd3fc', fg_muted: '#93c5fd', panel: '#102036'),
    'zhodani' => Palette.new(outline: '#ddd6fe', highlight: '#7c3aed', fg_muted: '#7b6f9f', panel: '#ffffff')
  }.freeze

  # An unknown or blank theme falls back to the default rather than raising, since it can
  # come straight from a request parameter or cookie.
  def self.key_for(theme)
    PALETTES.key?(theme.to_s) ? theme.to_s : DEFAULT
  end

  def self.palette(theme)
    PALETTES.fetch(key_for(theme))
  end
end
