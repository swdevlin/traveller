import { Controller } from '@hotwired/stimulus';

// Handles clicks on SVG <a data-hex-move> hexes. Turbo does not intercept SVG
// anchors, and a move must be a PATCH, so build a form and let Turbo submit it
// (which also runs the usual confirm dialog and follows the redirect).
export default class extends Controller {
  connect() {
    this._onClick = this.#handleClick.bind(this);
    this.element.addEventListener('click', this._onClick);
  }

  disconnect() {
    this.element.removeEventListener('click', this._onClick);
  }

  #handleClick(event) {
    const anchor = event.target.closest('a[data-hex-move]');
    if (!anchor) return;

    event.preventDefault();
    event.stopPropagation();

    const form = document.createElement('form');
    form.method = 'post';
    form.action = anchor.getAttribute('href');
    form.hidden = true;
    form.dataset.turboConfirm = anchor.dataset.hexMoveConfirm;
    this.#addField(form, '_method', 'patch');
    const token = document.querySelector('meta[name="csrf-token"]');
    if (token) this.#addField(form, 'authenticity_token', token.content);
    document.body.appendChild(form);
    form.requestSubmit();
  }

  #addField(form, name, value) {
    const input = document.createElement('input');
    input.type = 'hidden';
    input.name = name;
    input.value = value;
    form.appendChild(input);
  }
}
