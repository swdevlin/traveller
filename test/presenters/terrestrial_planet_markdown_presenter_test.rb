require 'test_helper'

class TerrestrialPlanetMarkdownPresenterTest < ActiveSupport::TestCase
  test 'renders no-population messages when population, government, law, and tech codes are all 0' do
    planet = stellar_objects(:two)
    planet.size_code = '5'
    planet.atmosphere_code = 5
    planet.hydrographics_code = 5
    planet.population_code = 0
    planet.government_code = 0
    planet.law_level_code = 0
    planet.tech_level_code = 0
    planet.save!

    markdown = TerrestrialPlanetMarkdownPresenter.new(planet).render

    assert_includes markdown, 'No government (population 0).'
    assert_includes markdown, 'No law level (population 0).'
    assert_includes markdown, 'No tech level (population 0).'
    assert_not_includes markdown, '## Structure'
    assert_not_includes markdown, 'Judicial Structure'
    assert_not_includes markdown, 'Sub-Classifications'
  end

  test 'renders real government/law/tech detail when population is 0 but those codes are greater than 0' do
    planet = stellar_objects(:two)
    planet.size_code = '5'
    planet.atmosphere_code = 5
    planet.hydrographics_code = 5
    planet.population_code = 0
    planet.government_code = 1
    planet.law_level_code = 1
    planet.tech_level_code = 1
    planet.save!

    markdown = TerrestrialPlanetMarkdownPresenter.new(planet).render

    assert_not_includes markdown, 'No government (population 0).'
    assert_not_includes markdown, 'No law level (population 0).'
    assert_not_includes markdown, 'No tech level (population 0).'
    assert_includes markdown, '## Government'
    assert_includes markdown, '## Law Level'
    assert_includes markdown, '## Tech Level'
  end

  test 'renders government/law/tech detail when population is present' do
    planet = stellar_objects(:two)
    planet.size_code = '5'
    planet.atmosphere_code = 5
    planet.hydrographics_code = 5
    planet.population_code = 5
    planet.government_code = 1
    planet.law_level_code = 1
    planet.tech_level_code = 1
    planet.save!

    markdown = TerrestrialPlanetMarkdownPresenter.new(planet).render

    assert_not_includes markdown, 'No government (population 0).'
    assert_not_includes markdown, 'No law level (population 0).'
    assert_not_includes markdown, 'No tech level (population 0).'
    assert_includes markdown, '## Government'
    assert_includes markdown, '## Law Level'
    assert_includes markdown, '## Tech Level'
  end

  test 'renders starport capacity when the world has it, leaving out figures that do not apply' do
    planet = stellar_objects(:two)
    planet.update_column(:data, (planet.data || {}).merge(
      'starport_capacity' => { 'hasHighport' => false, 'highport' => nil, 'downport' => 808_000,
                               'shipyardCapability' => 'smallCraft', 'shipyardBuildCapacity' => nil }
    ))

    markdown = TerrestrialPlanetMarkdownPresenter.new(planet).render

    assert_not_includes markdown, '## Starport Capacity'
    assert_match(/## Starport\n.*\| Highport \| None \|.*## /m, markdown)
    assert_includes markdown, '| Highport | None |'
    assert_includes markdown, '| Downport Capacity | 808,000 tons |'
    assert_includes markdown, '| Shipyard | Small craft |'
    assert_not_includes markdown, 'Highport Capacity'
    assert_not_includes markdown, 'Shipyard Build Capacity'
  end

  test 'omits the starport capacity section when the world has no capacity data' do
    markdown = TerrestrialPlanetMarkdownPresenter.new(stellar_objects(:two)).render

    assert_not_includes markdown, 'Highport'
  end
end
