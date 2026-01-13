import {Controller} from '@hotwired/stimulus';

export default class extends Controller {
  static targets = [
    'randomToggle',
    'starConfig',
    // Primary star
    'primaryFields',
    'primarySpectralType',
    'primarySpectralSubtype',
    'primaryLuminosity',
    // Primary companion
    'primary_companionSection',
    'primary_companionToggle',
    'primary_companionContainer',
    'primary_companionSpectralType',
    'primary_companionSpectralSubtype',
    'primary_companionLuminosity',
    // Close star
    'closeToggle',
    'closeContainer',
    'closeSpectralType',
    'closeSpectralSubtype',
    'closeLuminosity',
    // Close companion
    'close_companionSection',
    'close_companionToggle',
    'close_companionContainer',
    'close_companionSpectralType',
    'close_companionSpectralSubtype',
    'close_companionLuminosity',
    // Near star
    'nearToggle',
    'nearContainer',
    'nearSpectralType',
    'nearSpectralSubtype',
    'nearLuminosity',
    // Near companion
    'near_companionSection',
    'near_companionToggle',
    'near_companionContainer',
    'near_companionSpectralType',
    'near_companionSpectralSubtype',
    'near_companionLuminosity',
    // Far star
    'farToggle',
    'farContainer',
    'farSpectralType',
    'farSpectralSubtype',
    'farLuminosity',
    // Far companion
    'far_companionSection',
    'far_companionToggle',
    'far_companionContainer',
    'far_companionSpectralType',
    'far_companionSpectralSubtype',
    'far_companionLuminosity'
  ];

  connect() {
    this.applyRandom();
  }

  toggleRandom() {
    this.applyRandom();
  }

  toggleSection(event) {
    const prefix = event.params.prefix;
    this.applySection(prefix);
  }

  applyRandom() {
    const random = this.randomToggleTarget.checked;

    if (this.hasStarConfigTarget) {
      this.starConfigTarget.classList.toggle('hidden', random);
    }

    this.setFieldsDisabled('primary', random);

    const sections = ['primary_companion', 'close', 'close_companion', 'near', 'near_companion', 'far', 'far_companion'];
    sections.forEach(prefix => {
      const toggleTarget = `${prefix}ToggleTarget`;
      const hasToggle = `has${this.capitalize(prefix)}ToggleTarget`;

      if (this[hasToggle]) {
        const enabled = this[toggleTarget].checked && !random;
        this.setFieldsDisabled(prefix, !enabled || random);
      }
    })
  }

  applySection(prefix) {
    const toggleTarget = this[`${prefix}ToggleTarget`];
    const containerTarget = this[`${prefix}ContainerTarget`];
    const enabled = toggleTarget.checked;

    containerTarget.classList.toggle('hidden', !enabled);
    this.setFieldsDisabled(prefix, !enabled);

    if (!enabled) {
      this.clearFields(prefix);
    }

    // Show/hide companion section based on parent star state
    const companionPrefix = `${prefix}_companion`;
    const hasCompanionSection = this[`has${this.capitalize(companionPrefix)}SectionTarget`];
    if (hasCompanionSection) {
      const companionSection = this[`${companionPrefix}SectionTarget`];
      companionSection.classList.toggle('hidden', !enabled);

      // If hiding companion, also uncheck and clear it
      if (!enabled) {
        const hasCompanionToggle = this[`has${this.capitalize(companionPrefix)}ToggleTarget`];
        if (hasCompanionToggle) {
          const companionToggle = this[`${companionPrefix}ToggleTarget`];
          companionToggle.checked = false;
          const companionContainer = this[`${companionPrefix}ContainerTarget`];
          companionContainer.classList.add('hidden');
          this.clearFields(companionPrefix);
          this.setFieldsDisabled(companionPrefix, true);
        }
      }
    }
  }

  setFieldsDisabled(prefix, disabled) {
    const fields = ['SpectralType', 'SpectralSubtype', 'Luminosity'];
    fields.forEach(field => {
      const targetName = `${prefix}${field}Target`;
      const hasTarget = `has${this.capitalize(prefix)}${field}Target`;

      if (this[hasTarget]) {
        this.setDisabled(this[targetName], disabled);
      }
    })
  }

  clearFields(prefix) {
    const fields = ['SpectralType', 'SpectralSubtype', 'Luminosity'];
    fields.forEach(field => {
      const targetName = `${prefix}${field}Target`;
      const hasTarget = `has${this.capitalize(prefix)}${field}Target`;

      if (this[hasTarget]) {
        this[targetName].value = '';
      }
    })
  }

  setDisabled(el, disabled) {
    if (!el) return;
    el.disabled = disabled;
    el.classList.toggle('opacity-50', disabled);
  }

  capitalize(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
  }
}
