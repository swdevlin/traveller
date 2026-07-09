class SimpleStellarObjectMarkdownPresenter < MarkdownPresenterBase
  private

  def type_sections
    (@obj.orbiting ? orbital_data_section : []) + jump_shadow_section
  end
end
