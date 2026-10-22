require 'test_helper'

class RasteriseSectorMapJobTest < ActiveSupport::TestCase
  SVG = '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="200"><rect width="50" height="50" fill="red"/></svg>'.freeze

  test 'is not tracked by the nav bar job counter' do
    assert_includes JobQueueStatus::UNTRACKED_QUEUES, RasteriseSectorMapJob.new.queue_name
    assert_not_operator RasteriseSectorMapJob, :<, ApplicationJob
  end

  test 'writes a webp for the version and purges older ones' do
    sector = Sector.kept.first || skip('no sector fixture')
    old_version = 'a' * 64
    version = 'b' * 64
    old_image = SectorMapImage.new(sector, old_version)
    image = SectorMapImage.new(sector, version)

    old_image.write(SVG)
    image.write(SVG)

    assert image.exist?
    assert_not old_image.exist?
  ensure
    FileUtils.rm_f([old_image&.path, image&.path].compact.map(&:to_s))
  end

  test 'rejects malformed versions' do
    assert_not SectorMapImage.valid_version?('../etc/passwd')
    assert SectorMapImage.valid_version?('a' * 64)
  end
end
