class ReleaseNote
  attr_reader :date_code, :markdown, :slug

  def initialize(date_code:, markdown:, slug:)
    @date_code = date_code
    @markdown = markdown
    @slug = slug
  end

  def released_on
    year_str, day_str = date_code.split('.')
    Date.ordinal(year_str.to_i, day_str.to_i)
  end

  def self.all
    Dir[Rails.root.join('content/releases/*.md')]
      .map { |path| from_file(path) }
      .sort_by(&:released_on)
      .reverse
  end

  def self.from_file(path)
    content = File.read(path)
    front_matter, markdown = parse(content)

    new(
      date_code: front_matter['date_code'],
      markdown: markdown,
      slug: File.basename(path, '.md')
    )
  end

  def self.parse(content)
    match = content.match(/\A---\s*\n(.*?)\n---\s*\n(.*)\z/m)
    raise ArgumentError, 'Invalid release note format' unless match

    front_matter = YAML.safe_load(match[1]) || {}
    markdown = match[2].strip

    [front_matter, markdown]
  end
end
