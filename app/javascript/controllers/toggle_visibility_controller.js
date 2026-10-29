import { Controller } from '@hotwired/stimulus';

// Shows this element only while a checkbox elsewhere in the same form is checked.
// `attribute` is the checkbox's field name, e.g. "extinct_sophont".
export default class extends Controller {
  static values = { attribute: String };

  connect() {
    this.checkbox = this.element.closest('form')?.querySelector(`input[type="checkbox"][name$="[${this.attributeValue}]"]`);
    if (!this.checkbox) return;

    this.listener = () => this.sync();
    this.checkbox.addEventListener('change', this.listener);
    this.sync();
  }

  disconnect() {
    this.checkbox?.removeEventListener('change', this.listener);
  }

  sync() {
    this.element.classList.toggle('hidden', !this.checkbox.checked);
  }
}
