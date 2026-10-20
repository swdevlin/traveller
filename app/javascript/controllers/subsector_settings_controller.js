import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['mode', 'section', 'row', 'density', 'maxTechLevel', 'settled', 'known'];

  changeMode() {
    const mode = this.currentMode();
    if (mode === 'subsectors') this.seedRows();

    this.sectionTargets.forEach((section) => {
      section.classList.toggle('hidden', !section.dataset.modes.split(' ').includes(mode));
    });
  }

  currentMode() {
    const selected = this.modeTargets.find((radio) => radio.checked);
    return selected ? selected.value : 'options';
  }

  // Start each row from the sector-wide choices so the grid only needs the exceptions.
  seedRows() {
    this.rowTargets.forEach((row) => {
      row.querySelector('[data-field="density"]').value = this.densityTarget.value;
      row.querySelector('[data-field="maxTechLevel"]').value = this.maxTechLevelTarget.value;
      this.setToggle(row.querySelector('[data-field="settled"]'), this.settledTarget.checked);
      this.setToggle(row.querySelector('[data-field="known"]'), this.knownTarget.checked);
    });
  }

  setToggle(checkbox, checked) {
    const element = checkbox.closest('[data-controller~="boolean-toggle"]');
    this.application.getControllerForElementAndIdentifier(element, 'boolean-toggle').set(checked);
  }
}
