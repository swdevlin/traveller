module SystemQueriesHelper
  # A condition's `values` are option codes/ids. These fields are
  # referee-editable rows with their own show pages, so link to them; every
  # other field just gets its plain-text label (`SystemQuery.value_label`
  # also supplies the link text, so sector/subsector keep their richer
  # "name (sector)" formatting).
  def filter_value_display(field, value)
    record = linkable_filter_record(field, value)
    return SystemQuery.value_label(field, value) unless record

    link_to SystemQuery.value_label(field, value), linkable_filter_path(field, record),
            class: 'no-underline hover:underline hover:underline-offset-2'
  end

  private

  def linkable_filter_record(field, value)
    case field
    when 'jump_route' then JumpRoute.find_by(id: value)
    when 'allegiance' then Allegiance.find_by(code: value)
    when 'sector'     then Sector.kept.find_by(id: value)
    when 'subsector'  then Subsector.kept_sector.find_by(id: value)
    end
  end

  def linkable_filter_path(field, record)
    case field
    when 'jump_route' then jump_route_path(record)
    when 'allegiance' then allegiance_path(record)
    when 'sector'     then sector_path(record)
    when 'subsector'  then subsector_path(record)
    end
  end
end
