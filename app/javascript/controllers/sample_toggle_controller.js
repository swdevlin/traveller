import { Controller } from '@hotwired/stimulus'

// Usage: data-controller="sample-toggle"
export default class extends Controller {
    static targets =  ['minimal', 'full', 'minimalButton', 'fullButton'];

    connect() {
        this.showMinimal()
    }

    showMinimal() {
        this.minimalTarget.classList.remove('hidden');
        this.fullTarget.classList.add('hidden');
        this.minimalButtonTarget.classList.add('pill-toggle-active');
        this.fullButtonTarget.classList.remove('pill-toggle-active');
    }

    showFull() {
        this.fullTarget.classList.remove('hidden')
        this.minimalTarget.classList.add('hidden')
        this.minimalButtonTarget.classList.remove('pill-toggle-active');
        this.fullButtonTarget.classList.add('pill-toggle-active');
    }
}
