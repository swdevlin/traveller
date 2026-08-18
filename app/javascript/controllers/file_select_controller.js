import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "submit"];

  connect() {
    this.toggle();
  }

  toggle() {
    this.submitTarget.disabled = this.inputTarget.files.length === 0;
  }
}
