import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['checkbox', 'skillEffect', 'brokerFields']

  connect() {
    this.sync()
  }

  sync() {
    const useBroker = this.checkboxTarget.checked
    this.skillEffectTarget.classList.toggle('hidden', useBroker)
    this.brokerFieldsTargets.forEach((el) => el.classList.toggle('hidden', !useBroker))
  }
}
