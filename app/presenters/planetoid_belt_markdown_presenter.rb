class PlanetoidBeltMarkdownPresenter < MarkdownPresenterBase
  private

  def type_sections
    orbital_data_section + jump_shadow_section + environmental_data_section +
      belt_composition_section + belt_data_section
  end

  def belt_composition_section
    rows = [
      ['Metallic', "#{@obj.m_type}%"],
      ['Stony', "#{@obj.s_type}%"],
      ['Carbonaceous', "#{@obj.c_type}%"],
      ['Other', "#{@obj.o_type}%"]
    ]
    table_section('Belt Composition', rows)
  end

  def belt_data_section
    rows = []
    if @obj.resource_rating.present?
      r = @obj.resource_rating
      rows << ['Resource Rating', "#{r} — #{RESOURCE_RATING_DESCRIPTIONS[r]}"]
    end
    rows << ['Bulk', @obj.bulk] if @obj.bulk.present?
    rows << ['Span', fmt(@obj.span, 2)] if @obj.span.present?
    rows << ['Significant Bodies', @obj.significant_bodies.count]
    rows << ['Native Sophont', @obj.native_sophont ? 'Yes' : 'No']
    rows << ['Extinct Sophont', @obj.extinct_sophont ? 'Yes' : 'No']
    table_section('Belt Data', rows)
  end
end
