import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['fileField', 'titleField', 'shortTitleField'];

  populateFromFile() {
    const file = this.fileFieldTarget.files[0];
    if (!file) return;

    const title = file.name.replace(/\.pdf$/i, '');

    if (!this.titleFieldTarget.value) {
      this.titleFieldTarget.value = title;
    }

    if (!this.shortTitleFieldTarget.value) {
      this.shortTitleFieldTarget.value = this.acronym(title);
    }
  }

  acronym(title) {
    return title
      .split(/\s+/)
      .filter(Boolean)
      .map((word) => word[0])
      .join('');
  }
}
