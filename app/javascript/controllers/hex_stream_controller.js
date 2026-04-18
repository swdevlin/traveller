import { Controller } from '@hotwired/stimulus'

// Handles turbo-stream requests from SVG <a data-turbo-stream> elements.
// Turbo's built-in link handler doesn't intercept SVG anchors because
// SVGAnimatedString (element.href) isn't a plain string — so we fetch manually.
export default class extends Controller {
  connect() {
    this._onClick = this.#handleClick.bind(this)
    this.element.addEventListener('click', this._onClick)
  }

  disconnect() {
    this.element.removeEventListener('click', this._onClick)
  }

  #handleClick(event) {
    const anchor = event.target.closest('a')
    if (!anchor || !anchor.hasAttribute('data-turbo-stream')) return

    event.preventDefault()
    event.stopPropagation()

    const href = anchor.getAttribute('href')
    if (!href) return

    fetch(href, {
      headers: { Accept: 'text/vnd.turbo-stream.html' },
      credentials: 'same-origin'
    })
      .then(r => r.text())
      .then(html => window.Turbo.renderStreamMessage(html))
  }
}
