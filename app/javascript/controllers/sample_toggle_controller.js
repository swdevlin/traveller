import { Controller } from '@hotwired/stimulus'

// Usage: data-controller="sample-toggle"
//   Tabs:   data-sample-toggle-target="tab"   data-name="minimal"  data-action="sample-toggle#show"  data-sample-toggle-name-param="minimal"
//   Panels: data-sample-toggle-target="panel"  data-name="minimal"
export default class extends Controller {
    static targets = ['panel', 'tab']

    connect() {
        const first = this.tabTargets[0]?.dataset.name
        if (first) this.select(first)
    }

    show({ params: { name } }) {
        this.select(name)
    }

    select(name) {
        this.panelTargets.forEach(el => el.classList.toggle('hidden', el.dataset.name !== name))
        this.tabTargets.forEach(el => el.classList.toggle('pill-toggle-active', el.dataset.name === name))
    }
}
