import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  start() {
    document.body.style.cursor = 'wait';
  }

  stop() {
    document.body.style.cursor = '';
  }
}
