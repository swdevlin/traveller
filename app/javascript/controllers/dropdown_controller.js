import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['menu']

  connect () {
    this._handleOutsideClick = this._handleOutsideClick.bind(this)
    document.addEventListener('click', this._handleOutsideClick)
  }

  disconnect () {
    document.removeEventListener('click', this._handleOutsideClick)
  }

  toggle () {
    const hidden = this.menuTarget.classList.toggle('hidden')
    this.element.querySelector('[aria-expanded]')?.setAttribute('aria-expanded', String(!hidden))
  }

  close () {
    this.menuTarget.classList.add('hidden')
    const trigger = this.element.querySelector('[aria-expanded]')
    trigger?.setAttribute('aria-expanded', 'false')
    trigger?.focus()
  }

  _handleOutsideClick (event) {
    if (event.target.closest('[data-turbo-tour-panel]')) return

    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add('hidden')
      this.element.querySelector('[aria-expanded]')?.setAttribute('aria-expanded', 'false')
    }
  }
}
