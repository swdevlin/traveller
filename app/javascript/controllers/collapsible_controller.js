import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['content', 'icon']

  toggle() {
    this.contentTarget.classList.toggle('max-h-14')
    this.contentTarget.classList.toggle('overflow-hidden')
    this.contentTarget.classList.toggle('notes-fade')

    const isCollapsed = this.contentTarget.classList.contains('max-h-14')
    this.iconTarget.classList.toggle('fa-square-chevron-down', isCollapsed)
    this.iconTarget.classList.toggle('fa-square-chevron-up', !isCollapsed)
  }
}