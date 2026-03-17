import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['input', 'label', 'panel']

  connect () {
    this._handleOutsideClick = this._handleOutsideClick.bind(this)
    document.addEventListener('click', this._handleOutsideClick)
  }

  disconnect () {
    document.removeEventListener('click', this._handleOutsideClick)
  }

  toggle () {
    this.panelTarget.classList.toggle('hidden')
  }

  select (event) {
    const btn = event.currentTarget
    this.inputTarget.value = btn.dataset.value
    this.labelTarget.textContent = btn.dataset.label
    this.panelTarget.classList.add('hidden')
    this.inputTarget.dispatchEvent(new Event('change', { bubbles: true }))
  }

  _handleOutsideClick (event) {
    if (!this.element.contains(event.target)) {
      this.panelTarget.classList.add('hidden')
    }
  }
}
