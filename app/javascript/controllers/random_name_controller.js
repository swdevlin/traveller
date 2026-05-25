import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['nameField', 'languageButton', 'languagePanel', 'languageInput', 'generateButton'];
  static values = { effectiveLanguage: String, wordUrl: String };

  connect() {
    this.updateButtonState();
    this.updateTooltip();
    this.boundHandleOutsideClick = this.handleOutsideClick.bind(this);
  }

  disconnect() {
    document.removeEventListener('click', this.boundHandleOutsideClick);
  }

  toggleLanguagePicker(event) {
    event.stopPropagation();
    if (this.languagePanelTarget.classList.contains('hidden')) {
      this.languagePanelTarget.classList.remove('hidden');
      document.addEventListener('click', this.boundHandleOutsideClick);
    } else {
      this.closePicker();
    }
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.closePicker();
    }
  }

  closePicker() {
    this.languagePanelTarget.classList.add('hidden');
    document.removeEventListener('click', this.boundHandleOutsideClick);
  }

  selectLanguage(event) {
    this.languageInputTarget.value = event.currentTarget.dataset.value;
    this.closePicker();
    this.updateButtonState();
    this.updateTooltip();
  }

  clearLanguage() {
    this.languageInputTarget.value = '';
    this.closePicker();
    this.updateButtonState();
    this.updateTooltip();
  }

  updateButtonState() {
    const hasLanguage = this.languageInputTarget.value || this.effectiveLanguageValue;
    this.generateButtonTarget.disabled = !hasLanguage;
  }

  updateTooltip() {
    const ownLang = this.languageInputTarget.value;
    const effectiveLang = this.effectiveLanguageValue;
    let title;

    if (ownLang) {
      title = `Language: ${this.capitalize(ownLang)}`;
    } else if (effectiveLang) {
      title = `Language: inherited (${this.capitalize(effectiveLang)})`;
    } else {
      title = 'Language: none set';
    }

    this.languageButtonTarget.title = title;
  }

  async generate(event) {
    event.preventDefault();
    const lang = this.languageInputTarget.value || this.effectiveLanguageValue;
    if (!lang) return;

    try {
      const response = await fetch(`${this.wordUrlValue}?language=${lang}`);
      if (!response.ok) return;
      const data = await response.json();
      if (data.word) {
        this.nameFieldTarget.value = data.word;
      }
    } catch (_e) {
      // ignore network errors silently
    }
  }

  capitalize(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
  }
}
