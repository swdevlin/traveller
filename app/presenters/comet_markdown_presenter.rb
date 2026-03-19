class CometMarkdownPresenter < MarkdownPresenterBase
  private

  def type_sections
    (@obj.orbiting ? orbital_data_section : []) + comet_data_section
  end

  def comet_data_section
    table_section('Comet Data', [['Type', @obj.comet_type_description]])
  end
end
