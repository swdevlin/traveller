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
end
