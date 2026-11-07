import { Controller } from '@hotwired/stimulus';
import { createConsumer } from '@rails/actioncable';

export default class extends Controller {
  static targets = ['pending', 'failed', 'message'];
  static values = { campaignId: Number, sectorsUrl: String };

  connect() {
    this.channel = createConsumer().subscriptions.create(
      { channel: 'CampaignProvisioningChannel', id: this.campaignIdValue },
      { received: (data) => this.handleMessage(data) }
    );
  }

  disconnect() {
    if (this.channel) {
      this.channel.unsubscribe();
    }
  }

  handleMessage(data) {
    if (data.event === 'ready') {
      Turbo.visit(this.sectorsUrlValue);
    } else if (data.event === 'failed') {
      this.pendingTarget.hidden = true;
      this.failedTarget.hidden = false;
      this.messageTarget.textContent = data.message;
    }
  }
}
