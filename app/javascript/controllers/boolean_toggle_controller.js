import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["checkbox", "button", "indicator"];

  toggle() {
    if (this.locked || this.checkboxTarget.disabled) return;
    const checkbox = this.checkboxTarget;
    checkbox.checked = !checkbox.checked;
    this.#updateVisual(checkbox.checked);
    checkbox.dispatchEvent(new Event("change", { bubbles: true }));
  }

  set(checked) {
    this.checkboxTarget.checked = checked;
    this.#updateVisual(checked);
  }

  // Locks the toggle against user interaction while keeping the checkbox enabled, so its
  // value is still submitted with the form — a real `disabled` checkbox is excluded from
  // submission, leaving only the hidden fallback field's value to go through instead.
  setDisabled(locked) {
    this.locked = locked;
    this.buttonTarget.setAttribute("aria-disabled", String(locked));
    this.buttonTarget.classList.toggle("opacity-50", locked);
    this.buttonTarget.classList.toggle("cursor-not-allowed", locked);
    this.buttonTarget.classList.toggle("cursor-pointer", !locked);
  }

  submitForm() {
    const form = this.element.closest("form");
    if (form) form.requestSubmit();
  }

  #updateVisual(checked) {
    this.buttonTarget.setAttribute("aria-checked", String(checked));
  }
}
