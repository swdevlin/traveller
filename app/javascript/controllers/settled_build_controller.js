import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['checkbox', 'textarea', 'fileInput', 'fileLockNotice'];
  static values = { settledYaml: String, basicYaml: String };

  toggle() {
    this.applyBuildSpec();
  }

  toggleFileLock() {
    this.applyBuildSpec();

    const locked = this.isFileLocked();
    this.textareaTarget.readOnly = locked;
    this.textareaTarget.classList.toggle('opacity-60', locked);
    this.textareaTarget.classList.toggle('cursor-not-allowed', locked);
    if (this.hasFileLockNoticeTarget) this.fileLockNoticeTarget.classList.toggle('hidden', !locked);
  }

  applyBuildSpec() {
    const yaml = this.checkboxTarget.checked ? this.settledYamlValue : this.basicYamlValue;

    // While a T5 file is attached it drives system placement (and any populated
    // block), so only defaultSI still applies from the Settled space toggle.
    this.textareaTarget.value = this.isFileLocked()
      ? `defaultSI: ${this.surveyIndexFrom(yaml)}\n`
      : yaml;
  }

  isFileLocked() {
    return this.hasFileInputTarget && this.fileInputTarget.files.length > 0;
  }

  surveyIndexFrom(yaml) {
    const match = yaml.match(/defaultSI:\s*(\d+)/);
    return match ? match[1] : '';
  }
}