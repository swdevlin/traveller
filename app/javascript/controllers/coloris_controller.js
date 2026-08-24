import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    Coloris({ el: this.element, themeMode: 'dark', format: 'hex', alpha: false })
  }
}
