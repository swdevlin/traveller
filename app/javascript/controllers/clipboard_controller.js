import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static values = { url: String, markdownUrl: String }
  static targets = ['source', 'copyBtn']

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

  copySource () {
    const text = Array.from(this.sourceTarget.children)
      .map(el => el.textContent.trim())
      .filter(Boolean)
      .join('\n')
    navigator.clipboard.writeText(text).then(() => {
      this.#flashCopyBtn()
    })
  }

  #flashCopyBtn () {
    if (!this.hasCopyBtnTarget) return
    const btn = this.copyBtnTarget
    const icon = btn.querySelector('i')
    if (icon) {
      icon.classList.replace('fa-copy', 'fa-check')
      setTimeout(() => icon.classList.replace('fa-check', 'fa-copy'), 1500)
    }
  }

  #flashIcon (from, to) {
    const icon = this.element.querySelector('i')
    if (!icon) return
    icon.classList.replace(from, to)
    setTimeout(() => icon.classList.replace(to, from), 1500)
  }
}
