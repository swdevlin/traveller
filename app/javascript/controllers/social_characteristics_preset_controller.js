import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['select', 'nameInput', 'saveError'];
  static values = { url: String };

  connect() {
    this.#loadList();
  }

  load() {
    const option = this.selectTarget.selectedOptions[0];
    if (!option?.dataset.settings) return;
    this.#applySettings(JSON.parse(option.dataset.settings));
  }

  async save() {
    const name = this.nameInputTarget.value.trim();
    if (!name) return;
    this.saveErrorTarget.textContent = '';

    const response = await fetch(this.urlValue, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': this.#csrfToken },
      body: JSON.stringify({ name, settings: this.#gatherSettings() }),
    });

    if (response.ok) {
      const preset = await response.json();
      this.#addOption(preset);
      this.nameInputTarget.value = '';
      this.selectTarget.value = String(preset.id);
    } else {
      const { errors } = await response.json();
      this.saveErrorTarget.textContent = errors.join(', ');
    }
  }

  async deletePreset() {
    const id = this.selectTarget.value;
    if (!id) return;
    await fetch(`${this.urlValue}/${id}`, {
      method: 'DELETE',
      headers: { 'X-CSRF-Token': this.#csrfToken },
    });
    this.selectTarget.selectedOptions[0]?.remove();
    this.selectTarget.value = '';
  }

  async #loadList() {
    const response = await fetch(this.urlValue, { headers: { Accept: 'application/json' } });
    const presets = await response.json();
    presets.forEach(p => this.#addOption(p));
  }

  #addOption(preset) {
    const opt = document.createElement('option');
    opt.value = String(preset.id);
    opt.textContent = preset.name;
    opt.dataset.settings = JSON.stringify(preset.settings);
    this.selectTarget.append(opt);
  }

  #applySettings(s) {
    const f = this.element;
    const set = (name, val) => {
      const el = f.querySelector(`[name="social_characteristics[${name}]"]`);
      if (el) el.value = val ?? '';
    };

    set('main_world_criteria', s.main_world_criteria);
    set('government_code', s.government_code);
    set('law_level_code', s.law_level_code);
    set('starport_code', s.starport_code);
    set('population][min', s.population?.min);
    set('population][max', s.population?.max);
    set('tech_level][min', s.tech_level?.min);
    set('tech_level][max', s.tech_level?.max);

    const checkbox = f.querySelector('[name="social_characteristics[allow_captive_government]"]');
    if (checkbox) checkbox.checked = s.allow_captive_government === '1';

    const comboEl = f.querySelector('[data-controller="allegiance-combobox"]');
    if (comboEl) {
      const ctrl = this.application.getControllerForElementAndIdentifier(comboEl, 'allegiance-combobox');
      ctrl?.loadById(s.allegiance_id);
    }
  }

  #gatherSettings() {
    const f = this.element;
    const val = name => f.querySelector(`[name="social_characteristics[${name}]"]`)?.value;
    return {
      main_world_criteria:      val('main_world_criteria'),
      government_code:          val('government_code'),
      law_level_code:           val('law_level_code'),
      starport_code:            val('starport_code'),
      allow_captive_government: f.querySelector('[name="social_characteristics[allow_captive_government]"]')?.checked ? '1' : '0',
      allegiance_id:            val('allegiance_id'),
      population: { min: val('population][min'), max: val('population][max') },
      tech_level: { min: val('tech_level][min'), max: val('tech_level][max') },
    };
  }

  get #csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content;
  }
}
