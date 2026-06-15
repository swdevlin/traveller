import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['selector', 'time']

  connect() {
    this.update();
  }

  update() {
    const g = this.selectorTarget.value;
    this.timeTargets.forEach(el => {
      const times = JSON.parse(el.dataset.times);
      el.textContent = times[g] || '-';
    });
  }
}