import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  set(event) {
    const theme = event.currentTarget.dataset.themeValue;

    document.cookie = `theme=${theme}; path=/; max-age=31536000; SameSite=Lax`;
    document.documentElement.dataset.theme = theme;
    window.location.reload();
  }
}