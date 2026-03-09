import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['shipSelect', 'misjumpCheckbox']

  #fromX = null
  #fromY = null
  #jumpDrive = 0

  connect() {
    const fromContainer = this.element.querySelector('[data-parsec-role="from"]')
    if (fromContainer?.dataset.fromX) {
      this.#fromX = parseInt(fromContainer.dataset.fromX)
      this.#fromY = parseInt(fromContainer.dataset.fromY)
    }

    const options = this.shipSelectTarget.querySelectorAll('option[value]:not([value=""])')
    if (options.length === 1 && !this.shipSelectTarget.value) {
      this.shipSelectTarget.value = options[0].value
    }

    const option = this.shipSelectTarget.selectedOptions[0]
    this.#jumpDrive = option ? parseInt(option.dataset.jumpDrive) || 0 : 0
    requestAnimationFrame(() => this.#applyConstraints())
  }

  shipChanged() {
    const option = this.shipSelectTarget.selectedOptions[0]
    this.#jumpDrive = option ? parseInt(option.dataset.jumpDrive) || 0 : 0
    this.#applyConstraints()
  }

  misjumpChanged() {
    this.#applyConstraints()
  }

  fromParsecSelected(event) {
    const fromContainer = this.element.querySelector('[data-parsec-role="from"]')
    if (!fromContainer?.contains(event.target)) return
    const { x, y } = event.detail
    this.#fromX = (x !== null && x !== undefined) ? x : null
    this.#fromY = (y !== null && y !== undefined) ? y : null
    this.#applyConstraints()
  }

  #applyConstraints() {
    const to = this.#toElement()
    if (!to) return

    const misjump = this.hasMisjumpCheckboxTarget && this.misjumpCheckboxTarget.checked

    if (this.#fromX !== null) {
      to.setAttribute('data-parsec-select-from-x-value', this.#fromX)
      to.setAttribute('data-parsec-select-from-y-value', this.#fromY)
    }
    to.setAttribute('data-parsec-select-max-distance-value', misjump ? 0 : this.#jumpDrive)

    if (misjump) {
      this.#showAllSectors()
    } else if (this.#fromX !== null && this.#jumpDrive > 0) {
      this.#updateToSector()
    }
  }

  #showAllSectors() {
    const sectorSelect = this.#toElement()?.querySelector('[data-parsec-select-target="sector"]')
    if (!sectorSelect) return

    Array.from(sectorSelect.querySelectorAll('option')).forEach(opt => {
      opt.hidden = false
    })
    sectorSelect.disabled = false
  }

  #updateToSector() {
    const sectorSelect = this.#toElement()?.querySelector('[data-parsec-select-target="sector"]')
    if (!sectorSelect) return

    const fx = this.#fromX, fy = this.#fromY, d = this.#jumpDrive
    const options = Array.from(sectorSelect.querySelectorAll('option[value]:not([value=""])'))
    const reachable = []

    options.forEach(opt => {
      const sx = parseInt(opt.dataset.sectorX)
      const sy = parseInt(opt.dataset.sectorY)
      if (isNaN(sx) || isNaN(sy)) return
      const sxMin = sx * 32, sxMax = sx * 32 + 31
      const syMin = sy * 40 - 39, syMax = sy * 40
      const cx = Math.max(sxMin, Math.min(sxMax, fx))
      const cy = Math.max(syMin, Math.min(syMax, fy))
      const inRange = Math.abs(fx - cx) <= d && Math.abs(fy - cy) <= d
      opt.hidden = !inRange
      if (inRange) reachable.push(opt)
    })

    if (reachable.length === 1) {
      const prev = sectorSelect.value
      sectorSelect.value = reachable[0].value
      sectorSelect.disabled = true
      if (prev !== reachable[0].value) {
        sectorSelect.dispatchEvent(new Event('change', { bubbles: true }))
      }
    } else {
      sectorSelect.disabled = false
    }
  }

  #toElement() {
    return this.element.querySelector('[data-parsec-role="to"]')
  }
}
