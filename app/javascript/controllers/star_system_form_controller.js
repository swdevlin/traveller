import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['starConfig', 'buildConfigSection', 'buildConfig']

  connect() {
    this.sync()
  }

  sync() {
    const mode = this.element.querySelector('input[name="star_system[create_mode]"]:checked')?.value

    if (this.hasStarConfigTarget) {
      const show = mode === 'empty'
      this.starConfigTarget.classList.toggle('hidden', !show)
      this.starConfigTarget.querySelectorAll('select').forEach(el => {
        if (show) {
          const container = el.closest('[data-star-system-form-section]')
          const sectionHidden = container ? container.classList.contains('hidden') : false
          if (sectionHidden) {
            el.disabled = true
          } else {
            el.disabled = this.#shouldDisableForDwarfType(el)
          }
        } else {
          el.disabled = true
        }
      })
    }

    if (this.hasBuildConfigSectionTarget) {
      this.buildConfigSectionTarget.classList.toggle('hidden', mode !== 'build_configuration')
    }

    if (this.hasBuildConfigTarget) {
      this.buildConfigTarget.disabled = mode !== 'build_configuration'
    }
  }

  spectralTypeChanged(event) {
    const select = event.currentTarget
    const section = select.closest('[data-star-system-form-section]')
    if (!section) return

    const noSubtype = ['BD', 'D'].includes(select.value)
    const subtypeSelect = section.querySelector('[data-role="spectral-subtype"]')
    const luminositySelect = section.querySelector('[data-role="luminosity"]')

    if (subtypeSelect) {
      subtypeSelect.disabled = noSubtype
      if (noSubtype) subtypeSelect.value = ''
    }
    if (luminositySelect) {
      luminositySelect.disabled = noSubtype
      if (noSubtype) luminositySelect.value = ''
    }
  }

  toggleSection({ params: { prefix } }) {
    const toggle = this.element.querySelector(`[data-star-system-form-prefix="${prefix}"][data-star-system-form-role="toggle"]`)
    const container = this.element.querySelector(`[data-star-system-form-prefix="${prefix}"][data-star-system-form-role="container"]`)
    if (!toggle || !container) return

    const checked = toggle.checked
    container.classList.toggle('hidden', !checked)
    container.querySelectorAll('select').forEach(el => el.disabled = !checked)

    // Hide companion section when parent is unchecked
    const companionSection = this.element.querySelector(`[data-star-system-form-prefix="${prefix}_companion"][data-star-system-form-role="section"]`)
    if (companionSection) {
      companionSection.classList.toggle('hidden', !checked)
      if (!checked) {
        companionSection.querySelectorAll('select').forEach(el => el.disabled = true)
      }
    }
  }

  #shouldDisableForDwarfType(el) {
    const role = el.dataset.role
    if (role !== 'spectral-subtype' && role !== 'luminosity') return false

    const section = el.closest('[data-star-system-form-section]')
    if (!section) return false

    const typeSelect = section.querySelector('select:not([data-role])')
    return typeSelect && ['BD', 'D'].includes(typeSelect.value)
  }
}
