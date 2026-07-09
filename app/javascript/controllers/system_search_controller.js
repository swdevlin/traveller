import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['input', 'idField', 'dropdown', 'list']
  static values  = { searchUrl: String }

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

  #select(result) {
    this.inputTarget.value  = result.name
    this.idFieldTarget.value = result.id
    this.#closeDropdown()
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
