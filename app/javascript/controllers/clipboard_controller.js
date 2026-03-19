import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static values = { url: String }

  copy () {
    navigator.clipboard.writeText(this.urlValue).then(() => {
      const icon = this.element.querySelector('i')
      if (!icon) return
      icon.classList.replace('fa-link', 'fa-check')
      setTimeout(() => icon.classList.replace('fa-check', 'fa-link'), 1500)
    })
  }
}
