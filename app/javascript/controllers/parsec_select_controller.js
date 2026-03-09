import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['sector', 'hex', 'hiddenId']
  static values = {
    parsecId: Number,
    sectorId: Number,
    fromX: { type: String, default: '' },
    fromY: { type: String, default: '' },
    maxDistance: { type: Number, default: 0 }
  }

  #parsecs = []

  connect() {
    if (this.sectorIdValue) {
      this.loadHexes(this.sectorIdValue, this.parsecIdValue)
    }
  }

  sectorChanged() {
    const sectorId = this.sectorTarget.value
    this.hiddenIdTarget.value = ''
    if (sectorId) {
      this.loadHexes(sectorId, null)
    } else {
      this.#parsecs = []
      this.hexTarget.innerHTML = '<option value="">Select a hex</option>'
      this.hexTarget.disabled = true
    }
  }

  hexChanged() {
    this.hiddenIdTarget.value = this.hexTarget.value
    const selected = this.#parsecs.find(p => p.id === parseInt(this.hexTarget.value))
    this.dispatch('hex-selected', { detail: { x: selected?.x ?? null, y: selected?.y ?? null } })
  }

  fromXValueChanged() { this.#filterAndRender() }
  fromYValueChanged() { this.#filterAndRender() }
  maxDistanceValueChanged() { this.#filterAndRender() }

  async loadHexes(sectorId, selectedParsecId) {
    const response = await fetch(`/api/parsecs?sector_id=${sectorId}`)
    this.#parsecs = await response.json()
    this.#filterAndRender(selectedParsecId)
  }

  #filterAndRender(selectedParsecId = null) {
    if (this.#parsecs.length === 0) return

    const current = selectedParsecId ?? (this.hiddenIdTarget.value ? parseInt(this.hiddenIdTarget.value) : null)
    let visible = this.#parsecs

    if (this.maxDistanceValue > 0 && this.fromXValue !== '' && this.fromYValue !== '') {
      const fx = parseInt(this.fromXValue)
      const fy = parseInt(this.fromYValue)
      visible = this.#parsecs.filter(p => this.#hexDistance(fx, fy, p.x, p.y) <= this.maxDistanceValue)
    }

    this.hexTarget.innerHTML =
      '<option value="">Select a hex</option>' +
      visible.map(p => `<option value="${p.id}"${p.id === current ? ' selected' : ''}>${p.hex_code}</option>`).join('')
    this.hexTarget.disabled = false

    if (current && visible.some(p => p.id === current)) {
      this.hexTarget.value = current
      this.hiddenIdTarget.value = current
    } else if (current && !visible.some(p => p.id === current)) {
      // Previously selected parsec is now out of range
      this.hiddenIdTarget.value = ''
    }
  }

  // Odd-q offset hex grid distance (odd 0-indexed columns = even Traveller columns, shifted up)
  #hexDistance(x1, y1, x2, y2) {
    const r1 = (-y1) - Math.floor((x1 - (x1 & 1)) / 2)
    const r2 = (-y2) - Math.floor((x2 - (x2 & 1)) / 2)
    const s1 = -x1 - r1
    const s2 = -x2 - r2
    return Math.max(Math.abs(x1 - x2), Math.abs(r1 - r2), Math.abs(s1 - s2))
  }
}
