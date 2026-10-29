require 'test_helper'

class TaggableTest < ActiveSupport::TestCase
  test 'system tags include tags from every associated body' do
    system = star_systems(:in_one)
    system.update!(tag_list: 'Research')
    body = StellarObject.where(star_system_id: system.id).first!
    body.update!(tag_list: 'Research, Frontier')
    assert_includes system.contained_tags, 'Research'
    assert_includes system.contained_tags, 'Frontier'
    assert_equal system.contained_tags.uniq, system.contained_tags
  end

  test 'all map objects normalize and persist multiple tags and allow clearing them' do
    [sectors(:one), subsectors(:subsector_1_1), star_systems(:in_one), StellarObject.first, regions(:one)].each do |record|
      record.tag_list = ' Research, Frontier, Research, , <script> '
      record.save!
      assert_equal ['<script>', 'Frontier', 'Research'].sort, record.reload.tag_names.sort
      assert_equal record.tag_names.join(', '), record.tag_list
      record.tag_list = ''
      record.save!
      assert_equal [], record.reload.tag_names
    end
  end

  test 'removing the last use of a tag keeps the tag' do
    record = sectors(:one)
    record.update!(tag_list: 'Lonely')
    record.update!(tag_list: '')
    assert_includes Tag.names, 'Lonely'
    assert_equal 0, Tag.find_by!(name: 'Lonely').usage_count
  end

  test 'renaming onto an existing tag merges the assignments' do
    record = sectors(:one)
    record.update!(tag_list: 'Old, New')
    Tag.find_by!(name: 'Old').rename!('New')
    assert_equal ['New'], record.reload.tag_names
    assert_not_includes Tag.names, 'Old'
  end

  test 'deleting a tag removes its taggings' do
    record = sectors(:one)
    record.update!(tag_list: 'Gone, Kept')
    Tag.find_by!(name: 'Gone').destroy!
    assert_equal ['Kept'], record.reload.tag_names
  end

  test 'tags are listed alphabetically regardless of case or assignment order' do
    record = sectors(:one)
    record.update!(tag_list: 'zeta, Beta, alpha, Gamma')
    assert_equal %w[alpha Beta Gamma zeta], record.tag_names
    assert_equal %w[alpha Beta Gamma zeta], record.reload.sorted_tags.map(&:name)
    assert_equal %w[alpha Beta Gamma zeta], Tag.names
  end
end
