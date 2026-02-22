import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = [
    'stellarType', 'stellarSubtype', 'stellarClass',
    'mass', 'diameter', 'temperature', 'luminosity',
    'age', 'minimumOrbit', 'hzco', 'colour'
  ]
  static values = { lookupUrl: String }

  classify() {
    const stellarType = this.stellarTypeTarget.value
    if (!stellarType) return

    const url = new URL(this.lookupUrlValue, window.location.origin)
    url.searchParams.set('stellar_type', stellarType)

    const subtype = this.stellarSubtypeTarget.value
    if (subtype !== '') url.searchParams.set('stellar_subtype', subtype)

    const stellarClass = this.stellarClassTarget.value
    if (stellarClass !== '') url.searchParams.set('stellar_class', stellarClass)

    fetch(url, { headers: { 'Accept': 'application/json' } })
      .then(response => {
        if (!response.ok) return null
        return response.json()
      })
      .then(data => {
        if (!data) return
        this.#updateFields(data)
      })
      .catch(() => {})
  }

  #updateFields(data) {
    const set = (target, value) => {
      if (value !== undefined && value !== null) target.value = value
    }
    set(this.massTarget, data.mass)
    set(this.diameterTarget, data.diameter)
    set(this.temperatureTarget, data.temperature)
    set(this.luminosityTarget, data.luminosity)
    set(this.ageTarget, data.age)
    set(this.minimumOrbitTarget, data.minimumAllowableOrbit)
    set(this.hzcoTarget, data.hzco)
    set(this.colourTarget, data.colour)
  }
}
