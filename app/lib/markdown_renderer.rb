# frozen_string_literal: true

class MarkdownRenderer
  OPTIONS = {
    parse: {
      smart: true
    },
    render: {
      hardbreaks: true,
      unsafe: false
    },
    extension: {
      autolink: true,
      strikethrough: true,
      table: true,
      tagfilter: true,
      tasklist: true
    }
  }.freeze

  def self.render(markdown, options: OPTIONS)
    return '' if markdown.blank?

    Commonmarker.to_html(markdown.to_s, options: options)
  end
end
