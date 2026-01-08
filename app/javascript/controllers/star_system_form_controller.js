import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
    static targets = ['randomToggle', 'spectralType', 'spectralSubtype', 'luminosity']

    connect () {
        this.apply()
    }

    toggleRandom () {
        this.apply()
    }

    clear (el) {
        el.value = ''
    }

    apply () {
        const random = this.randomToggleTarget.checked

        if (random) {
            this.clear(this.spectralTypeTarget)
            this.clear(this.spectralSubtypeTarget)
            this.clear(this.luminosityTarget)
        }

        this.setDisabled(this.spectralTypeTarget, random)
        this.setDisabled(this.spectralSubtypeTarget, random)
        this.setDisabled(this.luminosityTarget, random)
    }

    setDisabled (el, disabled) {
        el.disabled = disabled
        el.classList.toggle('opacity-50', disabled)
    }
}
