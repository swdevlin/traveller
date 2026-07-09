import { Controller } from '@hotwired/stimulus'
import { setTheme } from 'theme'

export default class extends Controller {
  set(event) {
    setTheme(event.currentTarget.dataset.themeValue);
  }
}