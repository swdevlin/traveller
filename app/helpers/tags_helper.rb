module TagsHelper
  # One shared JSON list of tag names per page, read by every tag picker in a grid.
  def shared_tag_names_tag
    return if @shared_tag_names_rendered

    @shared_tag_names_rendered = true
    tag.script(raw(ERB::Util.json_escape(Tag.names.to_json)), type: 'application/json', id: 'shared-tag-names')
  end

  # Load the tags for every row of a grid in one query rather than one per row.
  def preload_tags(records)
    records = records.to_a
    ActiveRecord::Associations::Preloader.new(records: records, associations: :tags).call if records.any?
    records
  end
end
