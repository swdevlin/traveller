class ReleaseNotesController < ApplicationController
  allow_unauthenticated_access

  def index
    @pagy, @releases = pagy(:offset, ReleaseNote.all, limit: 10)
  end

  def feed
    feed = RSS::Maker.make('2.0') do |maker|
      maker.channel.title = 'My Traveller Universe Deltas'
      maker.channel.link = deltas_url(campaign_slug: nil)
      maker.channel.description = 'Release notes for Traveller'
      maker.channel.language = 'en-GB'
      maker.channel.updated = Time.now.utc

      ReleaseNote.all.first(20).each do |release|
        maker.items.new_item do |item|
          item.title = release.title
          item.link = deltas_url(anchor: release.slug, campaign_slug: nil)
          item.guid.content = "#{deltas_url(campaign_slug: nil)}##{release.slug}"
          item.guid.isPermaLink = false
          item.pubDate = release.released_on.to_time.utc
          item.description = helpers.render_markdown(release.markdown)
        end
      end
    end

    render xml: feed.to_s, content_type: 'application/rss+xml'
  end
end
