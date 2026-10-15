import { Controller } from '@hotwired/stimulus';

const SECTIONS = ['orbital', 'starport', 'physical', 'atmosphere', 'hydrographics', 'population', 'government', 'law_level', 'tech_level'];

// Appends the currently selected UWP tab to the Edit link as ?section=
export default class extends Controller {
  static values = { storageKey: String };

  go() {
    let tab = null;
    try {
      tab = sessionStorage.getItem(this.storageKeyValue);
    } catch (e) {
      tab = null;
    }
    if (!SECTIONS.includes(tab)) return;

    const url = new URL(this.element.href, window.location.origin);
    url.searchParams.set('section', tab);
    this.element.href = url.toString();
  }
}
