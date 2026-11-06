import { Controller } from '@hotwired/stimulus';

// Hamburger menu for table rows. The list is positioned with `fixed` so the
// table's scroll container cannot clip it.
export default class extends Controller {
  static targets = ['button', 'menu'];

  connect() {
    this._outside = (event) => {
      if (!this.element.contains(event.target)) this.close();
    };
    this._escape = (event) => {
      if (event.key === 'Escape' && this.isOpen) {
        this.close();
        this.buttonTarget.focus();
      }
    };
    this._reposition = () => this.close();
    document.addEventListener('click', this._outside);
    document.addEventListener('keydown', this._escape);
    window.addEventListener('scroll', this._reposition, true);
    window.addEventListener('resize', this._reposition);
  }

  disconnect() {
    document.removeEventListener('click', this._outside);
    document.removeEventListener('keydown', this._escape);
    window.removeEventListener('scroll', this._reposition, true);
    window.removeEventListener('resize', this._reposition);
  }

  get isOpen() {
    return !this.menuTarget.classList.contains('hidden');
  }

  toggle() {
    if (this.isOpen) {
      this.close();
    } else {
      this.open();
    }
  }

  open() {
    const menu = this.menuTarget;
    menu.classList.remove('hidden');
    const rect = this.buttonTarget.getBoundingClientRect();
    const height = menu.offsetHeight;
    const width = menu.offsetWidth;
    const below = rect.bottom + 4;
    const top = below + height > window.innerHeight ? Math.max(4, rect.top - height - 4) : below;
    menu.style.top = `${top}px`;
    menu.style.left = `${Math.max(4, rect.right - width)}px`;
    this.buttonTarget.setAttribute('aria-expanded', 'true');
    const first = menu.querySelector('[role="menuitem"]');
    if (first) first.focus();
  }

  close() {
    this.menuTarget.classList.add('hidden');
    this.buttonTarget.setAttribute('aria-expanded', 'false');
  }

  openDialog(event) {
    this.close();
    const dialog = document.getElementById(event.params.dialog);
    if (dialog) dialog.showModal();
  }
}
