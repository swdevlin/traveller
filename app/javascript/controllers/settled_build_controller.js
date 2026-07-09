import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['checkbox', 'textarea'];
  static values = { settledYaml: String, basicYaml: String };

  toggle() {
    this.textareaTarget.value = this.checkboxTarget.checked
      ? this.settledYamlValue
      : this.basicYamlValue;
  }
}