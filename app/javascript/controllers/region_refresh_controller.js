import { Controller } from '@hotwired/stimulus'
import { createConsumer } from '@rails/actioncable'

export default class extends Controller {
  static values = { regionId: Number }

  connect() {
    this.channel = createConsumer().subscriptions.create(
      { channel: 'RegionChannel', id: this.regionIdValue },
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
