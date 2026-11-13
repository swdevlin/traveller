require 'test_helper'

class SectorMapVersionTest < ActiveSupport::TestCase
  setup do
    @sector = sectors(:one)
    @campaign = campaigns(:one)
  end

  def digest
    SectorMapVersion.new(Sector.find(@sector.id), @campaign).digest
  end

  test 'digest is stable when nothing changes' do
    assert_equal digest, digest
  end

  test 'editing a star system changes the digest' do
    before = digest
    star_systems(:in_one).update!(name: 'Renamed')
    assert_not_equal before, digest
  end

  test 'editing a parsec changes the digest' do
    before = digest
    parsecs(:one).update!(note: 'changed')
    assert_not_equal before, digest
  end

  test 'editing a rogue stellar object changes the digest' do
    before = digest
    stellar_objects(:one).update!(name: 'Renamed rogue')
    assert_not_equal before, digest
  end

  test 'editing something in another sector leaves the digest alone' do
    before = digest
    star_systems(:in_two).update!(name: 'Renamed elsewhere')
    assert_equal before, digest
  end

  test 'a star system created in the sector changes the digest' do
    before = digest
    StarSystem.create!(name: 'New', parsec: parsecs(:one))
    assert_not_equal before, digest
  end

  test 'destroying a star system changes the digest' do
    before = digest
    star_systems(:hierarchy_system).destroy!
    assert_not_equal before, digest
  end

  test 'clearing a sector in bulk changes the digest' do
    before = digest
    @sector.clear
    assert_not_equal before, digest
  end
end
