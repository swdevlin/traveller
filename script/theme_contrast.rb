#!/usr/bin/env ruby
# frozen_string_literal: true

# WCAG 2.2 AA contrast audit of the theme palettes in app/assets/tailwind/application.css.
#
#   ruby script/theme_contrast.rb              # failures and low-margin passes only
#   ruby script/theme_contrast.rb --all        # every pair
#   ruby script/theme_contrast.rb --theme kkree
#
# Each pair names a foreground token and a background (possibly several translucent layers)
# that the app really uses together. Pairs that depend on rendered content (text over the map
# backdrop, form-plugin checkboxes, etc.) are listed under MANUAL at the end of the report.

CSS_PATH = File.expand_path('../app/assets/tailwind/application.css', __dir__)

THRESHOLDS = { text: 4.5, large: 3.0, ui: 3.0 }.freeze
MARGIN_TARGET = 4.8

# [label, foreground, background, kind]
#   foreground: token name, or [token, alpha]
#   background: token name, or array of layers bottom-up: ['bg', ['nav-bar', 0.95]]
#   kind: :text (4.5), :large (3.0, >=24px or >=18.66px bold) or :ui (3.0 non-text)
SURFACES = %w[bg panel panel-muted].freeze

PAIRS = [] # rubocop:disable Style/MutableConstant

def add(label, fg, bg, kind = :text)
  PAIRS << [label, fg, bg, kind]
end

SURFACES.each do |s|
  add "body text (fg) on #{s}", 'fg', s
  add "muted text (fg-muted) on #{s}", 'fg-muted', s
  add "bright text (fg-bright) on #{s}", 'fg-bright', s
  add "link on #{s}", 'link', s
  add "link hover on #{s}", 'link-hover', s
  add "small accent text (highlight-fg) on #{s}", 'highlight-fg', s
  add "heading accent (highlight, h1/h2/page-title) on #{s}", 'highlight', s, :large
  add "notice text on #{s}", 'notice', s
  add "danger text on #{s}", 'danger-text', s
  add "gauge line on #{s}", 'gauge-line', s, :ui
end

# Navigation
nav = ['bg', ['nav-bar', 0.95]]
add 'navbar link (nav-fg) on nav-bar', 'nav-fg', nav
add 'navbar link hover (nav-hover) on nav-bar', 'nav-hover', nav
add 'navbar campaign name (highlight-fg) on nav-bar', 'highlight-fg', nav
add 'nav-fg on dropdown', 'nav-fg', 'dropdown'
add 'nav-hover on dropdown-hover', 'nav-hover', 'dropdown-hover'
add 'nav-fg on dropdown-hover', 'nav-fg', 'dropdown-hover'
add 'fg on dropdown', 'fg', 'dropdown'
add 'fg on dropdown-hover', 'fg', 'dropdown-hover'
add 'fg-muted on dropdown', 'fg-muted', 'dropdown'
add 'fg-muted on dropdown-hover', 'fg-muted', 'dropdown-hover'
add 'link on dropdown', 'link', 'dropdown'

# Buttons
add '.btn: fg-bright on button', 'fg-bright', 'button'
add '.btn-primary: button-primary-fg on button-primary', 'button-primary-fg', 'button-primary'
add '.btn-primary hover (90%) over bg', 'button-primary-fg', ['bg', ['button-primary', 0.9]]
add '.btn-primary hover (90%) over panel', 'button-primary-fg', ['panel', ['button-primary', 0.9]]
add '.btn-danger: danger-fg on danger-bg over panel', 'danger-fg', ['panel', 'danger-bg']
add '.btn-danger: danger-fg on danger-bg over bg', 'danger-fg', ['bg', 'danger-bg']
add '.btn-danger hover: white on danger', 'white', 'danger'
add '.btn-header: fg on panel', 'fg', 'panel'
add '.btn-header hover: highlight-fg on panel', 'highlight-fg', 'panel'
add 'danger-muted (error bullet) on danger-bg over panel', 'danger-muted', ['panel', 'danger-bg'], :ui
add 'action-group danger: danger text on panel-muted', 'danger-text', 'panel-muted'

# Series nav / pills / identifiers
add 'series-nav: fg-bright on panel-muted', 'fg-bright', 'panel-muted'
add 'series-nav hover: highlight-fg on panel', 'highlight-fg', 'panel'
add 'series-nav current: bg text on highlight-fg fill', 'bg', 'highlight-fg'
add '.identifier: fg-bright on panel-muted', 'fg-bright', 'panel-muted'
add '.pill / .t-pill: fg on panel', 'fg', 'panel'
add '.pill-toggle-active: highlight-fg on panel', 'highlight-fg', 'panel'

# Forms
add 'input text: fg on panel-muted', 'fg', 'panel-muted'
add 'input placeholder: fg-muted on panel-muted', 'fg-muted', 'panel-muted'
add 'edit-label: fg-muted on bg (text-xs)', 'fg-muted', 'bg'
add 'edit-label: fg-muted on panel (text-xs)', 'fg-muted', 'panel'
add 'input border (control-outline) vs panel-muted', 'control-outline', 'panel-muted', :ui
add 'input border (control-outline) vs bg', 'control-outline', 'bg', :ui
add 'input border (control-outline) vs panel', 'control-outline', 'panel', :ui
add 'focus ring (highlight) on panel-muted', 'highlight', 'panel-muted', :ui
add 'focus ring (highlight) on bg', 'highlight', 'bg', :ui
add 'focus ring (highlight) on panel', 'highlight', 'panel', :ui

# Tables
add 'table th/td: fg on panel-muted', 'fg', 'panel-muted'
add 'table thead: fg on panel', 'fg', 'panel'
add 'table row hover: fg on table-hover', 'fg', 'table-hover'
add 'table row hover: fg-bright on table-hover', 'fg-bright', 'table-hover'
add 'table row hover: highlight-fg (t-link) on table-hover', 'highlight-fg', 'table-hover'
add 'table row hover: link on table-hover', 'link', 'table-hover'
add 'table row hover: fg-muted action on table-hover', 'fg-muted', 'table-hover'
add 'table action (fg-muted, text-xs) on panel-muted', 'fg-muted', 'panel-muted'
add 'table action danger hover on table-hover', 'danger-text', 'table-hover'
add 'table banner text: fg on gradient-from', 'fg', 'panel-gradient-from'
add 'table banner text: fg on gradient-via', 'fg', 'panel-gradient-via'
add 'table banner text: fg on gradient-to', 'fg', 'panel-gradient-to'
add 'table banner icon (inherits fg) on gradient-via', 'fg', 'panel-gradient-via', :ui

# Tabs, breadcrumbs, menus, callouts
add 'uwp tab label: fg-muted on bg', 'fg-muted', 'bg'
add 'uwp tab active: fg-bright on panel', 'fg-bright', 'panel'
add 'uwp tab highlight code: highlight-fg on bg', 'highlight-fg', 'bg'
add 'uwp tab active indicator (highlight) vs bg', 'highlight', 'bg', :ui
add 'menu title: fg-bright on panel-muted', 'fg-bright', 'panel-muted'
add 'menu description: fg-muted on panel-muted', 'fg-muted', 'panel-muted'
add 'menu row hover: fg-muted on panel', 'fg-muted', 'panel'
add 'callout: fg on panel-muted', 'fg', 'panel-muted'
add 'build/source line: fg-muted on panel', 'fg-muted', 'panel'

# Alerts
add 'notice banner: notice-fg on notice-bg over panel', 'notice-fg', ['panel', 'notice-bg']
add 'notice banner: notice-fg on notice-bg over bg', 'notice-fg', ['bg', 'notice-bg']
add 'danger banner: danger-fg on danger-bg over panel', 'danger-fg', ['panel', 'danger-bg']

# Toggles
add 'toggle on: knob vs track', 'toggle-knob-on', 'toggle-on', :ui
add 'toggle on: track vs panel', 'toggle-on', 'panel', :ui
add 'toggle off: knob vs track', 'toggle-knob-off', 'toggle-off', :ui
add 'toggle off: track vs panel', 'toggle-off', 'panel', :ui

MANUAL = [
  'Text over the sector/subsector map backdrop (depends on the rendered map).',
  'Starmap canvas/SVG colours and highlight-rule colours chosen by users.',
  'Browser-default form controls (checkbox/radio/select) from the Tailwind forms plugin.',
  'Text over bg-gradient or photographic overlays outside the table banner.',
  'Focus ring on elements using ring offsets over images.',
  'Disabled controls (exempt, but should remain legible): .btn:disabled, .series-nav .disabled.'
].freeze

# --- colour maths ------------------------------------------------------------------------

def parse_hex(str)
  m = str.strip.match(/\A#(\h{3}|\h{6}|\h{8})\z/) or return nil
  h = m[1]
  h = h.chars.map { |c| c * 2 }.join if h.length == 3
  rgb = h[0, 6].scan(/../).map { |x| x.to_i(16) }
  alpha = h.length == 8 ? h[6, 2].to_i(16) / 255.0 : 1.0
  [*rgb, alpha]
end

def blend(top, bottom, alpha = nil)
  a = alpha || top[3]
  Array.new(3) { |i| top[i] * a + bottom[i] * (1 - a) } + [1.0]
end

def luminance(c)
  r, g, b = c[0, 3].map do |v|
    s = v / 255.0
    s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055)**2.4
  end
  0.2126 * r + 0.7152 * g + 0.0722 * b
end

def contrast(fg, bg)
  l1, l2 = [luminance(fg), luminance(bg)].sort.reverse
  (l1 + 0.05) / (l2 + 0.05)
end

def to_hex(c)
  format('#%02x%02x%02x', *c[0, 3].map { |v| v.round.clamp(0, 255) })
end

# Tokens introduced for accessibility fall back to the token they split from, so the audit
# also runs against a stylesheet that has not been migrated yet.
FALLBACKS = {
  'highlight-fg' => 'highlight', 'control-outline' => 'outline', 'danger-text' => 'danger',
  'button-primary-fg' => 'traveller-red-foreground'
}.freeze

# --- theme loading -----------------------------------------------------------------------

class Themes
  attr_reader :themes

  def initialize(css = File.read(CSS_PATH))
    @themes = {}
    base = css[/@theme\s*\{(.*?)\n\}/m, 1]
    base_tokens = tokens(base)
    @themes['dark'] = base_tokens.dup
    css.scan(/:root\[data-theme='(\w+)'\]\s*\{(.*?)\n\}/m) do |name, body|
      @themes[name] = base_tokens.merge(tokens(body))
    end
  end

  def resolve(theme, name)
    return [255, 255, 255, 1.0] if name == 'white'

    value = @themes.fetch(theme)[name] || (FALLBACKS[name] && @themes.fetch(theme)[FALLBACKS[name]]) or return nil
    if (m = value.match(/\Avar\(--color-([\w-]+)\)\z/))
      resolve(theme, m[1])
    else
      parse_hex(value)
    end
  end

  def raw(theme, name) = @themes.fetch(theme)[name]

  def set(theme, name, hex)
    @themes.fetch(theme)[name] = hex
  end

  private

  def tokens(body)
    body.scan(/--color-([\w-]+):\s*([^;]+);/).to_h { |k, v| [k, v.strip] }
  end
end

def resolve_background(themes, theme, spec)
  layers = spec.is_a?(String) ? [spec] : spec
  layers.reduce(nil) do |under, layer|
    token, alpha = layer.is_a?(Array) ? layer : [layer, nil]
    c = themes.resolve(theme, token) or return nil
    under ? blend(c, under, alpha) : blend(c, [255, 255, 255, 1.0], alpha || 1.0)
  end
end

def describe_bg(spec)
  return spec if spec.is_a?(String)

  spec.reverse.map { |l| l.is_a?(Array) ? "#{l[0]}@#{(l[1] * 100).round}%" : l }.join(' over ')
end

def evaluate(themes, theme, pair)
  label, fg_spec, bg_spec, kind = pair
  fg_token, fg_alpha = fg_spec.is_a?(Array) ? fg_spec : [fg_spec, nil]
  bg = resolve_background(themes, theme, bg_spec)
  fg = themes.resolve(theme, fg_token)
  return nil unless fg && bg

  fg = blend(fg, bg, fg_alpha) if fg_alpha || fg[3] < 1
  ratio = contrast(fg, bg)
  { theme: theme, label: label, fg_token: fg_token, fg: to_hex(fg), bg_token: describe_bg(bg_spec),
    bg: to_hex(bg), ratio: ratio, kind: kind, threshold: THRESHOLDS.fetch(kind) }
end

# --- suggestions --------------------------------------------------------------------------


def rgb_to_hls(r, g, b)
  r, g, b = [r, g, b].map { |v| v / 255.0 }
  mx = [r, g, b].max
  mn = [r, g, b].min
  l = (mx + mn) / 2.0
  return [0.0, l, 0.0] if mx == mn

  d = mx - mn
  s = l > 0.5 ? d / (2.0 - mx - mn) : d / (mx + mn)
  h = case mx
  when r then ((g - b) / d) % 6
  when g then ((b - r) / d) + 2
  else ((r - g) / d) + 4
  end
  [h / 6.0, l, s]
end

def hls_to_rgb(h, l, s)
  return [l * 255, l * 255, l * 255] if s.zero?

  q = l < 0.5 ? l * (1 + s) : l + s - l * s
  p = 2 * l - q
  [h + 1.0 / 3, h, h - 1.0 / 3].map do |t|
    t += 1 if t.negative?
    t -= 1 if t > 1
    v = if t < 1.0 / 6 then p + (q - p) * 6 * t
    elsif t < 0.5 then q
    elsif t < 2.0 / 3 then p + (q - p) * (2.0 / 3 - t) * 6
    else p
    end
    v * 255
  end
end

def with_lightness(colour, lightness)
  h, _l, s = rgb_to_hls(*colour[0, 3])
  hls_to_rgb(h, lightness.clamp(0.0, 1.0), s) + [1.0]
end

UI_TARGET = 3.2

def target_for(kind)
  kind == :text ? MARGIN_TARGET : UI_TARGET
end

# Pairs that involve a token, either as foreground or as one of the background layers.
def pairs_for(token)
  PAIRS.select do |_l, fg, bg, _k|
    fg_name = fg.is_a?(Array) ? fg.first : fg
    layers = bg.is_a?(String) ? [bg] : bg.map { |l| l.is_a?(Array) ? l.first : l }
    fg_name == token || layers.include?(token)
  end
end

def satisfied?(themes, theme, pairs)
  pairs.all? do |pair|
    r = evaluate(themes, theme, pair)
    r.nil? || r[:ratio] >= target_for(r[:kind])
  end
end

# Smallest lightness change (either direction) for `token` that satisfies every pair it is in.
def solve_token(themes, theme, token, pairs: pairs_for(token))
  base = themes.resolve(theme, token) or return nil
  return nil if satisfied?(themes, theme, pairs)

  original = themes.raw(theme, token)
  _h, l0, _s = rgb_to_hls(*base[0, 3])
  (1..400).each do |i|
    [1, -1].each do |dir|
      l = l0 + dir * i * 0.0025
      next if l.negative? || l > 1

      candidate = with_lightness(base, l)
      themes.set(theme, token, to_hex(candidate))
      return to_hex(candidate) if satisfied?(themes, theme, pairs)
    end
  end
  themes.set(theme, token, original)
  :none
end

# Picks the first candidate colour (an existing palette colour where possible) for text on a fill.
def choose_foreground(themes, theme, token, candidates)
  pairs = pairs_for(token)
  original = themes.raw(theme, token)
  candidates.each do |name|
    hex = name.start_with?('#') ? name : to_hex(themes.resolve(theme, name))
    themes.set(theme, token, hex)
    return hex if satisfied?(themes, theme, pairs)
  end
  themes.set(theme, token, original)
  :none
end

FG_TOKENS = %w[fg-muted link link-hover notice nav-fg nav-hover danger-fg notice-fg control-outline gauge-line
               danger-muted].freeze

def suggest(themes)
  out = Hash.new { |h, k| h[k] = {} }
  themes.themes.each_key do |theme|
    # Fills first: accent used for large headings, focus rings and filled chips.
    pending = {}
    r = solve_token(themes, theme, 'highlight')
    pending['highlight'] = r if r
    r = solve_token(themes, theme, 'danger', pairs: pairs_for('danger').select { |l, *| l.include?('hover: white') })
    pending['danger'] = r if r

    r = choose_foreground(themes, theme, 'button-primary-fg',
                          ['traveller-red-foreground', 'fg-bright', 'bg', '#111111', '#ffffff', '#000000'])
    if r == :none
      # No readable foreground at the current fill (usually the 90% hover blend): nudge the fill instead.
      themes.set(theme, 'button-primary-fg', to_hex(themes.resolve(theme, 'traveller-red-foreground')))
      fill = solve_token(themes, theme, 'button-primary', pairs: pairs_for('button-primary-fg'))
      pending['button-primary'] = fill if fill
      pending['button-primary-fg'] = themes.raw(theme, 'button-primary-fg')
    elsif r != themes.raw(theme, 'traveller-red-foreground')
      pending['button-primary-fg'] = r
    end

    %w[highlight-fg danger-text].each do |t|
      r = solve_token(themes, theme, t)
      pending[t] = r if r
    end
    FG_TOKENS.each do |t|
      r = solve_token(themes, theme, t)
      pending[t] = r if r
    end
    # Banner gradient stops sit behind text and actions, so they move rather than the text.
    %w[panel-gradient-via panel-gradient-to].each do |t|
      r = solve_token(themes, theme, t)
      pending[t] = r if r
    end

    # Toggles: the track must stand out from the panel, then the knob from the track.
    [%w[toggle-on toggle-knob-on], %w[toggle-off toggle-knob-off]].each do |track, knob|
      track_pairs = pairs_for(track).select { |label, *| label.include?('track vs panel') }
      r = solve_token(themes, theme, track, pairs: track_pairs)
      pending[track] = r if r
      r = solve_token(themes, theme, knob)
      pending[knob] = r if r
    end
    out[theme] = pending
  end
  out
end

ANCHORS = {
  'button-primary-fg' => 'button-primary-outline', 'highlight-fg' => 'highlight', 'danger-text' => 'danger',
  'control-outline' => 'outline', 'nav-hover' => 'nav-fg'
}.freeze

# Writes the suggested overrides into the stylesheet (replacing a token's line, or adding it
# after a related token, or at the end of the theme block).
def apply(suggestions)
  css = File.read(CSS_PATH)
  suggestions.each do |theme, tokens|
    tokens.each do |token, value|
      next if value == :none

      css.sub!(/(\n:root\[data-theme='aslan'\])/, "\n:root[data-theme='dark'] {\n}\n\\1") if theme == 'dark' && !css.include?("[data-theme='dark']")
      block_re = /(:root\[data-theme='#{theme}'\]\s*\{)(.*?)(\n\})/m
      css.sub!(block_re) do
        head = Regexp.last_match(1)
        body = Regexp.last_match(2)
        tail = Regexp.last_match(3)
        line_re = /^(\s*--color-#{Regexp.escape(token)}:)\s*[^;]+;/
        if body.match?(line_re)
          body = body.sub(line_re) { "#{Regexp.last_match(1)} #{value};" }
        else
          anchor = ANCHORS[token]
          anchor_re = anchor && /^(\s*--color-#{Regexp.escape(anchor)}:[^;]+;)/
          new_line = "  --color-#{token}: #{value};"
          body = if anchor_re && body.match?(anchor_re)
                   body.sub(anchor_re) { "#{Regexp.last_match(1)}\n#{new_line}" }
          else
                   "#{body}\n#{new_line}"
          end
        end
        head + body + tail
      end
    end
  end
  File.write(CSS_PATH, css)
end

def run(argv)
  if argv.include?('--apply')
    apply(suggest(Themes.new))
    return
  end

  if argv.include?('--suggest')
    themes = Themes.new
    suggest(themes).each do |theme, tokens|
      next if tokens.empty?

      puts "== #{theme}"
      tokens.each { |t, v| puts "  --color-#{t}: #{v}" }
    end
    return
  end

  all = argv.include?('--all')
  only = argv.include?('--theme') ? argv[argv.index('--theme') + 1] : nil
  themes = Themes.new
  fails = 0
  warns = 0
  themes.themes.each_key do |theme|
    next if only && theme != only

    rows = PAIRS.filter_map { |p| evaluate(themes, theme, p) }
    shown = rows.select do |r|
      r[:ratio] < r[:threshold] || (r[:kind] == :text && r[:ratio] < MARGIN_TARGET) || all
    end
    next if shown.empty?

    puts "\n== #{theme}"
    shown.each do |r|
      status = 'ok  '
      if r[:ratio] < r[:threshold]
        status = 'FAIL'
        fails += 1
      elsif r[:kind] == :text && r[:ratio] < MARGIN_TARGET
        status = 'LOW '
        warns += 1
      end
      puts format('  %<s>s %<ratio>5.2f (need %<need>.1f) %<label>s  [%<ft>s %<fh>s on %<bt>s %<bh>s]',
                  s: status, ratio: r[:ratio], need: r[:threshold], label: r[:label],
                  ft: r[:fg_token], fh: r[:fg], bt: r[:bg_token], bh: r[:bg])
    end
  end
  puts "\n#{fails} failing pair(s), #{warns} below the #{MARGIN_TARGET}:1 margin target."
  puts "\nNeeds manual browser verification:"
  MANUAL.each { |m| puts "  - #{m}" }
  exit(fails.positive? ? 1 : 0)
end

run(ARGV) if $PROGRAM_NAME == __FILE__
