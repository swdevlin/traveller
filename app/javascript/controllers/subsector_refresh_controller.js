import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static values = { subsectorId: Number }

  connect() {
    this.channel = createConsumer().subscriptions.create(
      { channel: "SubsectorChannel", id: this.subsectorIdValue },
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
    if (data.event === "populating" || data.event === "finished") {
      this.reload()
    }
  }

  reload() {
    const src = this.element.getAttribute("src")
    if (src) {
      this.element.src = ""
      this.element.src = src
    }
  }
}
