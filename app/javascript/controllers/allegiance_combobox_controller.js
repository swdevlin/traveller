import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['input', 'hidden', 'dropdown', 'list', 'clear']
  static values = { searchUrl: String }

  connect() {
    this.timer = null
    this.boundHandleOutsideClick = this.handleOutsideClick.bind(this)
    document.addEventListener('click', this.boundHandleOutsideClick)
  }

  disconnect() {
    document.removeEventListener('click', this.boundHandleOutsideClick)
    clearTimeout(this.timer)
  }

  search() {
    const q = this.inputTarget.value.trim()
    this.hiddenTarget.value = ''
    this.clearTarget.classList.add('hidden')
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.fetch({ q }), 200)
  }

  open() {
    const id = this.hiddenTarget.value
    clearTimeout(this.timer)
    this.timer = setTimeout(() => {
      if (id) {
        this.fetch({ id })
      } else {
        this.fetch({ q: this.inputTarget.value.trim() })
      }
    }, 0)
  }

  select(event) {
    const li = event.target.closest('[data-allegiance-id]')
    if (!li) return
    this.hiddenTarget.value = li.dataset.allegianceId
    this.inputTarget.value = li.dataset.allegianceText
    this.clearTarget.classList.remove('hidden')
    this.closeDropdown()
  }

  clear() {
    this.hiddenTarget.value = ''
    this.inputTarget.value = ''
    this.clearTarget.classList.add('hidden')
    this.closeDropdown()
  }

  async loadById(id) {
    if (!id) { this.clear(); return }
    const url = new URL(this.searchUrlValue, window.location.origin)
    url.searchParams.set('id', String(id))
    const response = await fetch(url, { headers: { Accept: 'application/json' } })
    const results = await response.json()
    if (results.length > 0) {
      const a = results[0]
      this.hiddenTarget.value = String(a.id)
      this.inputTarget.value = `${a.code} — ${a.name}`
      this.clearTarget.classList.remove('hidden')
    }
  }

  async fetch({ q, id } = {}) {
    const url = new URL(this.searchUrlValue, window.location.origin)
    if (id) url.searchParams.set('id', id)
    else if (q) url.searchParams.set('q', q)
    const response = await fetch(url, { headers: { Accept: 'application/json' } })
    const results = await response.json()
    this.render(results)
  }

  render(results) {
    this.listTarget.innerHTML = ''
    if (results.length === 0) {
      const empty = document.createElement('li')
      empty.className = 'px-3 py-2 text-slate-400 text-sm'
      empty.textContent = 'No matches'
      this.listTarget.appendChild(empty)
    } else {
      results.forEach(a => {
        const li = document.createElement('li')
        li.className = 'px-3 py-2 cursor-pointer hover:bg-slate-700 text-sm flex items-center gap-2'
        li.dataset.allegianceId = a.id
        li.dataset.allegianceText = `${a.code} — ${a.name}`

        const code = document.createElement('span')
        code.className = 'font-mono text-slate-300'
        code.textContent = a.code

        const name = document.createElement('span')
        name.className = 'text-slate-400'
        name.textContent = a.name

        li.appendChild(code)
        li.appendChild(name)
        this.listTarget.appendChild(li)
      })
    }
    this.dropdownTarget.classList.remove('hidden')
  }

  closeDropdown() {
    this.dropdownTarget.classList.add('hidden')
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.closeDropdown()
    }
  }
}
