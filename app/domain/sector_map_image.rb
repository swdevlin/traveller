# frozen_string_literal: true

# Rasterised (WebP) copy of a sector map, stored per tenant on disk and keyed by
# SectorMapVersion#digest so a stale image is never served.
class SectorMapImage
  VERSION_FORMAT = /\A\h{64}\z/

  def initialize(sector, version)
    @sector = sector
    @version = version
  end

  def self.valid_version?(version)
    version.to_s.match?(VERSION_FORMAT)
  end

  # Most recently written image for a sector, whatever data version it was built from.
  def self.latest(sector)
    dir = directory
    Dir.glob(dir.join("#{sector.id}-*.webp")).max_by { |file| File.mtime(file) }&.then { |file| Pathname.new(file) }
  end

  def self.directory
    Rails.root.join('storage', Apartment::Tenant.current, 'sector_maps')
  end

  def path
    directory.join("#{@sector.id}-#{@version}.webp")
  end

  def exist?
    path.exist?
  end

  def write(svg)
    FileUtils.mkdir_p(directory)
    File.binwrite(path, SvgRasteriser.webp(SvgRasteriser.embed_images(svg)))
    purge_stale
    path
  end

  private

  def directory = self.class.directory

  def purge_stale
    Dir.glob(directory.join("#{@sector.id}-*.webp")).each do |file|
      File.delete(file) unless file == path.to_s
    end
  end
end
