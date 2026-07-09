import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['results']

  clear () {
    this.resultsTarget.innerHTML = ''
  }
}
