import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["checkbox", "button", "indicator"];

  toggle() {
    const checkbox = this.checkboxTarget;
    checkbox.checked = !checkbox.checked;
    this.#updateVisual(checkbox.checked);
    checkbox.dispatchEvent(new Event("change", { bubbles: true }));
  }

  #updateVisual(checked) {
    this.buttonTarget.setAttribute("aria-checked", String(checked));
    this.buttonTarget.classList.toggle("bg-sky-700", checked);
    this.buttonTarget.classList.toggle("bg-slate-600", !checked);
    this.indicatorTarget.classList.toggle("translate-x-5", checked);
    this.indicatorTarget.classList.toggle("bg-white", checked);
    this.indicatorTarget.classList.toggle("translate-x-0", !checked);
    this.indicatorTarget.classList.toggle("bg-slate-300", !checked);
  }
}
