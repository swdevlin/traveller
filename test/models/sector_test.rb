require 'test_helper'

class SectorTest < ActiveSupport::TestCase
  test 'effective_language returns own language when set' do
    campaign = campaigns(:one)
    sector = Sector.new(x: 99, y: 99, language: 'aslan')
    assert_equal 'aslan', sector.effective_language(campaign)
  end

  test 'effective_language falls back to campaign default' do
    campaign = campaigns(:one)
    campaign.default_language = 'nordic'
    sector = Sector.new(x: 99, y: 99)
    assert_equal 'nordic', sector.effective_language(campaign)
  end

  test 'effective_language own language overrides campaign default' do
    campaign = campaigns(:one)
    campaign.default_language = 'nordic'
    sector = Sector.new(x: 99, y: 99, language: 'aslan')
    assert_equal 'aslan', sector.effective_language(campaign)
  end

  test 'effective_language returns nil when nothing set' do
    campaign = campaigns(:one)
    assert_nil Sector.new(x: 99, y: 99).effective_language(campaign)
  end

  test 'validates language must be a recognised language' do
    sector = sectors(:one)
    sector.language = 'klingon'
    assert_not sector.valid?
    assert sector.errors[:language].any?
  end

  test 'validates language allows blank' do
    sector = sectors(:one)
    sector.language = ''
    assert sector.valid?
  end
end
