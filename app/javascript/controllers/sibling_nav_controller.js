import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['current'];
  static values = { previous: String, next: String };

  connect() {
    this.boundKeydown = this.#keydown.bind(this);
    document.addEventListener('keydown', this.boundKeydown);
    if (this.hasCurrentTarget) this.currentTarget.scrollIntoView({ inline: 'center', block: 'nearest' });
  }

  disconnect() {
    document.removeEventListener('keydown', this.boundKeydown);
  }

  #keydown(event) {
    if (event.defaultPrevented || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return;
    if (event.target.closest('input, textarea, select, [contenteditable]')) return;

    const url = event.key === 'ArrowLeft' ? this.previousValue : event.key === 'ArrowRight' ? this.nextValue : '';
    if (!url) return;

    event.preventDefault();
    Turbo.visit(url);
  }
}
