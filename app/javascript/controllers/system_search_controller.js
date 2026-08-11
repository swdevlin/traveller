import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['input', 'idField', 'dropdown', 'list', 'systemData']
  static values  = { searchUrl: String, systemDataUrl: String, autoSubmit: Boolean }

  connect() {
    this.timer = null
    this.boundHandleOutsideClick = this.#handleOutsideClick.bind(this)
    document.addEventListener('click', this.boundHandleOutsideClick)
  }

  disconnect() {
    document.removeEventListener('click', this.boundHandleOutsideClick)
    clearTimeout(this.timer)
  }

  search() {
    const q = this.inputTarget.value.trim()
    clearTimeout(this.timer)

    // Clear selection when the user edits the field
    this.idFieldTarget.value = ''
    if (this.hasSystemDataTarget) {
      this.systemDataTarget.innerHTML = ''
    }

    if (q.length < 3) {
      this.#closeDropdown()
      return
    }

    this.timer = setTimeout(() => this.#fetch(q), 250)
  }

  async #fetch(q) {
    try {
      const url = new URL(this.searchUrlValue, window.location.origin)
      url.searchParams.set('q', q)
      const response = await fetch(url, { headers: { Accept: 'application/json' } })
      if (!response.ok || !response.headers.get('content-type')?.includes('application/json')) {
        this.#render([])
        return
      }
      const results = await response.json()
      this.#render(results)
    } catch {
      this.#render([])
    }
  }

  #render(results) {
    this.listTarget.innerHTML = ''

    if (results.length === 0) {
      const empty = document.createElement('li')
      empty.className = 'px-3 py-2 text-fg-muted text-sm'
      empty.textContent = 'No matches'
      this.listTarget.appendChild(empty)
    } else {
      results.forEach(result => {
        const li = document.createElement('li')
        li.className = 'px-3 py-2 cursor-pointer hover:bg-dropdown-hover transition'
        li.addEventListener('click', (event) => { event.stopPropagation(); this.#select(result) })

        const name = document.createElement('div')
        name.className = 'text-sm text-fg truncate'
        name.textContent = result.name
        li.appendChild(name)

        if (result.meta) {
          const meta = document.createElement('div')
          meta.className = 'text-xs text-fg-muted mt-0.5 truncate'
          meta.textContent = result.meta
          li.appendChild(meta)
        }

        this.listTarget.appendChild(li)
      })
    }

    this.dropdownTarget.classList.remove('hidden')
  }

  async #select(result) {
    this.inputTarget.value  = result.name
    this.idFieldTarget.value = result.id
    this.#closeDropdown()

    if (this.hasSystemDataUrlValue) {
      await this.#fetchSystemData(result.id)
    }

    if (this.autoSubmitValue && this.#allPickersFilled()) {
      this.element.closest('form')?.requestSubmit()
    }
  }

  async #fetchSystemData(id) {
    try {
      const url = new URL(this.systemDataUrlValue, window.location.origin)
      url.searchParams.set('id', id)
      const response = await fetch(url, { headers: { Accept: 'application/json' } })
      if (!response.ok) return

      const data = await response.json()
      this.#renderSystemData(data)
    } catch {
      // leave any previously rendered system data in place
    }
  }

  #renderSystemData({ uwp, trade_codes: tradeCodes, travel_zone: travelZone, modifiers }) {
    if (!this.hasSystemDataTarget) return

    this.systemDataTarget.innerHTML = ''

    const wrapper = document.createElement('div')
    wrapper.className = 'mt-2 text-xs text-fg-muted space-y-0.5'

    const uwpLine = document.createElement('div')
    uwpLine.className = 'font-mono text-fg'
    uwpLine.textContent = uwp || '—'
    wrapper.appendChild(uwpLine)

    const codesLine = document.createElement('div')
    const codesText = tradeCodes && tradeCodes.length > 0 ? tradeCodes.join(' ') : '—'
    codesLine.textContent = travelZone ? `${codesText} · ${travelZone} Zone` : codesText
    wrapper.appendChild(codesLine)

    modifiers.forEach(modifier => {
      const line = document.createElement('div')
      const sign = modifier.value >= 0 ? '+' : ''
      line.textContent = `${modifier.label} (${sign}${modifier.value})`
      wrapper.appendChild(line)
    })

    this.systemDataTarget.appendChild(wrapper)
  }

  // Only relevant when autoSubmit is enabled: don't submit until every
  // system-search picker sharing this form has a selection.
  #allPickersFilled() {
    const form = this.element.closest('form')
    if (!form) return false

    return Array.from(form.querySelectorAll("[data-system-search-target='idField']"))
      .every(field => field.value.trim() !== '')
  }

  #closeDropdown() {
    this.dropdownTarget.classList.add('hidden')
    this.listTarget.innerHTML = ''
  }

  #handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.#closeDropdown()
    }
  }
}
