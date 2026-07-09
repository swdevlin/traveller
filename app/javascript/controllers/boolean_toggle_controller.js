import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["checkbox", "button", "indicator"];

  toggle() {
    const checkbox = this.checkboxTarget;
    checkbox.checked = !checkbox.checked;
    this.#updateVisual(checkbox.checked);
    checkbox.dispatchEvent(new Event("change", { bubbles: true }));
  }

  submitForm() {
    const form = this.element.closest("form");
    if (form) form.requestSubmit();
  }

  #updateVisual(checked) {
    this.buttonTarget.setAttribute("aria-checked", String(checked));
    this.buttonTarget.classList.toggle("bg-toggle-on", checked);
    this.buttonTarget.classList.toggle("bg-toggle-off", !checked);
    this.indicatorTarget.classList.toggle("translate-x-5", checked);
    this.indicatorTarget.classList.toggle("bg-toggle-knob-on", checked);
    this.indicatorTarget.classList.toggle("translate-x-0", !checked);
    this.indicatorTarget.classList.toggle("bg-toggle-knob-off", !checked);
  }
}
