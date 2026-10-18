import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['content', 'icon']
  static values = { collapseClass: { type: String, default: '' } }

  toggle(event) {
    // Clicks on header actions (links, buttons) must not toggle via the banner; the chevron has its own action.
    if (event && event.currentTarget !== event.target.closest('button') && event.target.closest('.actions')) return;

    if (this.collapseClassValue) {
      const isCollapsed = this.contentTarget.classList.toggle(this.collapseClassValue)
      this.iconTarget.classList.toggle('fa-square-chevron-down', isCollapsed)
      this.iconTarget.classList.toggle('fa-square-chevron-up', !isCollapsed)
    } else {
      this.contentTarget.classList.toggle('max-h-14')
      this.contentTarget.classList.toggle('overflow-hidden')
      this.contentTarget.classList.toggle('notes-fade')

      const isCollapsed = this.contentTarget.classList.contains('max-h-14')
      this.iconTarget.classList.toggle('fa-square-chevron-down', isCollapsed)
      this.iconTarget.classList.toggle('fa-square-chevron-up', !isCollapsed)
    }
  }
}
