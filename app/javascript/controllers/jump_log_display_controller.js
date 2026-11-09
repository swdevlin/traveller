import { Controller } from '@hotwired/stimulus';

// Shows only the jump log fields that apply to the chosen display mode.
export default class extends Controller {
  static targets = ['mode', 'fill', 'line'];

  connect () {
    this.toggle();
  }

  toggle () {
    const mode = this.modeTarget.value;
    const showFill = mode === 'fill' || mode === 'both';
    const showLine = mode === 'line' || mode === 'both';

    this.fillTargets.forEach((row) => row.classList.toggle('hidden', !showFill));
    this.lineTargets.forEach((row) => row.classList.toggle('hidden', !showLine));
  }
}
