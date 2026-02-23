import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['content', 'icon']

  toggle() {
    this.contentTarget.classList.toggle('hidden')

    const isHidden = this.contentTarget.classList.contains('hidden')
    this.iconTarget.classList.toggle('fa-square-chevron-up', !isHidden)
    this.iconTarget.classList.toggle('fa-square-chevron-down', isHidden)
  }
}