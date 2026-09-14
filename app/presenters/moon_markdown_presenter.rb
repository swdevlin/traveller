class MoonMarkdownPresenter < PlanetaryBodyMarkdownPresenter
  private

  def periapsis_apoapsis_rows
    [
      ['Periapsis', "#{number_with_delimiter(@obj.periapsis.round)} km"],
      ['Apoapsis', "#{number_with_delimiter(@obj.apoapsis.round)} km"]
    ]
  end
end
