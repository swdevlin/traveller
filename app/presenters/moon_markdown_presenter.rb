class MoonMarkdownPresenter < MarkdownPresenterBase
  private

  def type_sections
    orbital_data_section +
      physical_data_section +
      environmental_data_section +
      atmosphere_section +
      hydrographics_section +
      biological_data_section +
      social_data_section
  end
end
