class GasGiantMarkdownPresenter < MarkdownPresenterBase
  private

  def type_sections
    orbital_data_section + jump_shadow_section + gas_giant_physical_section
  end

  def gas_giant_physical_section
    rows = [
      ['Diameter', "#{number_with_delimiter(@obj.diameter&.round)} km"],
      ['Mass', "#{fmt(@obj.mass, 2)} ☉"],
      ['Rotation', "#{fmt(@obj.rotation, 2)} hours"]
    ]
    rows << ['Size', "#{@obj.code} #{GasGiant::SIZES[@obj.code] || @obj.code}"] if @obj.respond_to?(:code) && @obj.code.present?
    table_section('Physical Data', rows)
  end
end
