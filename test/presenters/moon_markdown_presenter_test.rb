require 'test_helper'

class MoonMarkdownPresenterTest < ActiveSupport::TestCase
  test 'renders no-population messages when population, government, law, and tech codes are all 0' do
    moon = moons(:orbiting_gas_giant)
    moon.population_code = 0
    moon.government_code = 0
    moon.law_level_code = 0
    moon.tech_level_code = 0
    moon.save!

    markdown = MoonMarkdownPresenter.new(moon).render

    assert_includes markdown, 'No government (population 0).'
    assert_includes markdown, 'No law level (population 0).'
    assert_includes markdown, 'No tech level (population 0).'
  end

  test 'renders real government/law/tech values when population is 0 but those codes are greater than 0' do
    moon = moons(:orbiting_gas_giant)
    moon.population_code = 0
    moon.government_code = 1
    moon.law_level_code = 1
    moon.tech_level_code = 1
    moon.save!

    markdown = MoonMarkdownPresenter.new(moon).render

    assert_not_includes markdown, 'No government (population 0).'
    assert_not_includes markdown, 'No law level (population 0).'
    assert_not_includes markdown, 'No tech level (population 0).'
    assert_includes markdown, 'Code 1 government'
    assert_includes markdown, 'Law Level | 1 — MyString'
    assert_includes markdown, 'Tech Level | 1 —'
  end

  test 'renders periapsis and apoapsis in whole-number km, not au' do
    moon = moons(:orbiting_gas_giant)
    moon.data = moon.data.merge('periapsis' => 1234.5, 'apoapsis' => 5678.9)
    moon.save!

    markdown = MoonMarkdownPresenter.new(moon).render

    assert_includes markdown, 'Periapsis | 1,235 km'
    assert_includes markdown, 'Apoapsis | 5,679 km'
  end
end
