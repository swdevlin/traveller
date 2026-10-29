import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['dialog', 'input'];

  open() {
    this.dialogTarget.showModal();
    this.inputTarget.focus();
  }

  close() {
    this.dialogTarget.close();
  }

  // Clicks on the backdrop land on the dialog element itself.
  backdrop(event) {
    if (event.target === this.dialogTarget) this.close();
  }

  // Keep clicks inside the dialog from triggering the surrounding row link.
  stop(event) {
    event.stopPropagation();
  }
}
