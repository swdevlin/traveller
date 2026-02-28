import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // On a fresh page load, Coloris's init() runs on DOMContentLoaded which fires
    // after ES modules execute, so the picker may not exist yet. Defer in that case.
    if (document.getElementById('clr-picker')) {
      this.#initColoris()
    } else {
      document.addEventListener('DOMContentLoaded', () => this.#initColoris(), { once: true })
    }
  }

  #initColoris() {
    Coloris({ el: this.element, themeMode: 'dark', format: 'hex', alpha: false })
  }
}
