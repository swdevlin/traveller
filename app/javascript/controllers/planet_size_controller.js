import { Controller } from "@hotwired/stimulus"

const EARTH_DIAMETER = 12742

export default class extends Controller {
  static targets = ["size", "diameter", "density", "mass", "gravity"]

  sizeChanged() {
    const size = parseInt(this.sizeTarget.value)
    if (size >= 1 && size <= 15) {
      this.diameterTarget.value = size * 1600
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
