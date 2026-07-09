import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['sectorSource']

  toggleSectorSource (event) {
    const isDeepnight = event.target.value === 'deepnight_revelation'
    this.sectorSourceTarget.classList.toggle('hidden', !isDeepnight)
  }
}
