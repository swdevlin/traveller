import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static values = { url: String, markdownUrl: String }

  copy () {
    navigator.clipboard.writeText(this.urlValue).then(() => {
      this.#flashIcon('fa-link', 'fa-check')
    })
  }

  copyMarkdown () {
    fetch(this.markdownUrlValue, { headers: { Accept: 'text/markdown' } })
      .then(r => r.text())
      .then(text => navigator.clipboard.writeText(text))
      .then(() => this.#flashIcon('fa-markdown', 'fa-check'))
  }

  #flashIcon (from, to) {
    const icon = this.element.querySelector('i')
    if (!icon) return
    icon.classList.replace(from, to)
    setTimeout(() => icon.classList.replace(to, from), 1500)
  }
}
