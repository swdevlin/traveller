import { Controller } from '@hotwired/stimulus'
import { createConsumer } from '@rails/actioncable'

export default class extends Controller {
  static values = { regionId: Number, campaignSlug: String }

  connect() {
    this.channel = createConsumer().subscriptions.create(
      { channel: 'RegionChannel', id: this.regionIdValue, campaign_slug: this.campaignSlugValue },
      {
        received: (data) => this.handleMessage(data)
      }
    )
  }

  disconnect() {
    if (this.channel) {
      this.channel.unsubscribe()
    }
  }

  handleMessage(data) {
    if (data.event === 'finished') {
      Turbo.visit(window.location.href, { action: 'replace' })
    }
  }
}
