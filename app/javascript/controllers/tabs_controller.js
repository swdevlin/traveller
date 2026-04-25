import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['tab', 'panel']
  static values = { default: String, storageKey: String }

  connect() {
    const stored = this.storageKeyValue ? sessionStorage.getItem(this.storageKeyValue) : null
    const initial = stored || this.defaultValue
    if (initial) this.#activate(initial)
  }

  switch(event) {
    const tab = event.currentTarget.dataset.tab
    this.#activate(tab)
    if (this.storageKeyValue) sessionStorage.setItem(this.storageKeyValue, tab)
  }

  #activate(tab) {
    this.tabTargets.forEach(t => {
      const active = t.dataset.tab === tab
      t.classList.toggle('uwp-tab-active', active)
      t.classList.toggle('uwp-tab-inactive', !active)
    })
    this.panelTargets.forEach(p => {
      p.classList.toggle('hidden', p.dataset.tab !== tab)
    })
  }
}
