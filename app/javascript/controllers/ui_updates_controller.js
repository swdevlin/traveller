import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static values = { event: String, sectorId: Number, src: String }

  connect() {
    this.channel = createConsumer().subscriptions.create(
      { channel: "UiUpdatesChannel" },
      {
        received: (data) => this.handleMessage(data)
      }
    );
  }

  disconnect() {
    if (this.channel) {
      this.channel.unsubscribe();
    }
  }

  handleMessage(data) {
    if (this.hasSectorIdValue) {
      if (data.sector_id !== this.sectorIdValue) return;
    } else if (this.hasEventValue) {
      const events = this.eventValue.split(/\s+/);
      if (!events.includes(data.event)) return;
    } else {
      return;
    }
    this.reload();
  }

  reload() {
    const src = this.hasSrcValue ? this.srcValue : this.element.getAttribute("src");
    if (src) {
      this.element.src = "";
      this.element.src = src;
    }
  }

}
