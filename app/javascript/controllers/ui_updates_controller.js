import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static values = { event: String }

  connect() {
    this.channel = createConsumer().subscriptions.create(
      { channel: "UiUpdatesChannel" },
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
    if (!this.hasEventValue || data.event !== this.eventValue) return
    this.reload()
  }

  reload() {
    const src = this.element.getAttribute("src")
    if (src) {
      this.element.src = ""
      this.element.src = src
    }
  }

}
