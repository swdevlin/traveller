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
          el.disabled = container ? container.classList.contains('hidden') : false
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
}
