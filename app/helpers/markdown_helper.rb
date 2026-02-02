# frozen_string_literal: true

module MarkdownHelper
  CALLOUT_PATTERN = /\A\[\!(?<type>[A-Z]+)\](?:\s+(?<title>.+))?\z/i.freeze

  ALLOWED_TAGS = %w[
    a p br hr
    strong em del code pre blockquote
    ul ol li
    h1 h2 h3 h4 h5 h6
    table thead tbody tr th td
    div
  ].freeze

  ALLOWED_ATTRIBUTES = %w[
    href title target rel
    class
  ].freeze

  def render_markdown(markdown)
    html = MarkdownRenderer.render(markdown)

    fragment = Loofah.fragment(html)
    fragment.scrub!(callout_scrubber)
    fragment.scrub!(mailto_link_scrubber)
    fragment.scrub!(external_link_scrubber)

    safe = sanitize(
      fragment.to_s,
      tags: ALLOWED_TAGS,
      attributes: ALLOWED_ATTRIBUTES
    )

    safe.html_safe
  end

  private

  def mailto_link_scrubber
    Loofah::Scrubber.new do |node|
      next unless node.name == 'a'

      href = node['href'].to_s
      next unless href.start_with?('mailto:')

      # mailto is a no no
      node.remove(node.text.to_s)
    end
  end

  def external_link_scrubber
    Loofah::Scrubber.new do |node|
      next unless node.name == 'a'

      href = node['href'].to_s

      # Only http(s) gets new tab behaviour
      next unless href.start_with?('http://', 'https://')

      node['target'] = '_blank'
      node['rel'] = 'noopener noreferrer'
    end
  end

  def callout_scrubber
    Loofah::Scrubber.new do |node|
      next unless node.name == 'blockquote'

      first_p = node.element_children.first
      next unless first_p&.name == 'p'

      first_line = first_p.text.to_s.lines.first&.strip
      next if first_line.blank?

      match = CALLOUT_PATTERN.match(first_line)
      next unless match

      type = match[:type].downcase
      title = (match[:title].presence || match[:type].capitalize).to_s

      remaining = first_p.text.to_s.lines.drop(1).join
      if remaining.strip.empty?
        first_p.remove
      else
        first_p.content = remaining.lstrip
      end

      doc = node.document
      wrapper = doc.create_element('div')
      wrapper['class'] = "callout callout-#{type}"

      title_div = doc.create_element('div')
      title_div['class'] = 'callout-title'
      title_div.content = title

      body_div = doc.create_element('div')
      body_div['class'] = 'callout-body'

      node.children.to_a.each { |child| body_div.add_child(child) }

      wrapper.add_child(title_div)
      wrapper.add_child(body_div)

      node.replace(wrapper)
    end
  end
end
