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

  // Reload one at a time. A burst of events (e.g. sixteen subsectors being created) would
  // otherwise start overlapping frame loads that cancel each other; events arriving while a
  // load is in flight are coalesced into a single follow-up reload.
  async reload() {
    if (this.loading) {
      this.reloadPending = true;
      return;
    }

    const src = this.hasSrcValue ? this.srcValue : this.element.getAttribute("src");
    if (!src) return;

    this.loading = true;
    try {
      if (this.element.getAttribute("src") === src) {
        await this.element.reload();
      } else {
        this.element.src = src;
        await this.element.loaded;
      }
    } catch (error) {
      console.error("ui-updates reload failed", error);
    } finally {
      this.loading = false;
      if (this.reloadPending) {
        this.reloadPending = false;
        this.reload();
      }
    }
  }

}
