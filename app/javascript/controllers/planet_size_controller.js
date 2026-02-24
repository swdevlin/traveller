import { Controller } from "@hotwired/stimulus"

const EARTH_DIAMETER = 12742

export default class extends Controller {
  static targets = ["size", "diameter", "density", "mass", "gravity"]

  sizeChanged() {
    const sizeCode = this.sizeTarget.value
    let diameter
    if (sizeCode === 'S') {
      diameter = 600
    } else {
      const size = parseInt(sizeCode, 16)
      if (!isNaN(size) && size >= 1) diameter = size * 1600
    }
    if (diameter !== undefined) {
      this.diameterTarget.value = diameter
      this.recalculate()
    }
  }

  recalculate() {
    const diameter = parseFloat(this.diameterTarget.value)
    const density = parseFloat(this.densityTarget.value)
    if (isNaN(diameter) || isNaN(density)) return

    const ratio = diameter / EARTH_DIAMETER
    this.gravityTarget.value = parseFloat((density * ratio).toPrecision(5))
    this.massTarget.value = parseFloat((density * Math.pow(ratio, 3)).toPrecision(5))
  }
}
