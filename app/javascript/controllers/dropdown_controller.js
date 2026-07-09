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
    this.menuTarget.classList.toggle('hidden')
  }

  _handleOutsideClick (event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add('hidden')
    }
  }
}
