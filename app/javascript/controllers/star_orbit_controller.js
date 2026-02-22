import { Controller } from '@hotwired/stimulus'

const TABLE = [
  0,
  0.4, 0.7, 1.0, 1.6, 2.8, 5.2, 10, 20, 40, 77,
  154, 308, 615, 1230, 2500, 4900, 9800, 19500, 39500, 78700
]

function orbitToAu(orbit) {
  if (isNaN(orbit)) return null
  if (orbit === 20) return TABLE[20]
  if (orbit > 20) return TABLE[20] + (orbit - 20) * (TABLE[20] - TABLE[19])
  const o = Math.trunc(orbit)
  const d = orbit - o
  return TABLE[o] + (TABLE[o + 1] - TABLE[o]) * d
}

export default class extends Controller {
  static targets = ['orbit', 'au']

  recalculate() {
    const orbit = parseFloat(this.orbitTarget.value)
    const au = orbitToAu(orbit)
    if (au !== null) {
      this.auTarget.value = parseFloat(au.toPrecision(5))
    }
  }
}
