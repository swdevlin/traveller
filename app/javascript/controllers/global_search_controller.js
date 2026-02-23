import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['input', 'dropdown', 'list', 'hint']
  static values = { searchUrl: String }

  connect() {
    this.timer = null
    this.boundHandleOutsideClick = this.#handleOutsideClick.bind(this)
    this.boundHandleKeydown = this.#handleKeydown.bind(this)
    document.addEventListener('click', this.boundHandleOutsideClick)
    document.addEventListener('keydown', this.boundHandleKeydown)
  }

  disconnect() {
    document.removeEventListener('click', this.boundHandleOutsideClick)
    document.removeEventListener('keydown', this.boundHandleKeydown)
    clearTimeout(this.timer)
  }

  inputFocused() {
    if (this.hasHintTarget) this.hintTarget.classList.add('hidden')
  }

  inputBlurred() {
    if (this.hasHintTarget && !this.inputTarget.value) this.hintTarget.classList.remove('hidden')
  }

  search() {
    const q = this.inputTarget.value.trim()
    clearTimeout(this.timer)

    if (q.length < 3) {
      this.#closeDropdown()
      return
    }

    this.timer = setTimeout(() => this.#fetch(q), 250)
  }

  async #fetch(q) {
    const url = new URL(this.searchUrlValue, window.location.origin)
    url.searchParams.set('q', q)
    const response = await fetch(url, { headers: { Accept: 'application/json' } })
    const results = await response.json()
    this.#render(results)
  }

  #render(results) {
    this.listTarget.innerHTML = ''

    if (results.length === 0) {
      const empty = document.createElement('li')
      empty.className = 'px-3 py-2 text-slate-400 text-sm'
      empty.textContent = 'No matches'
      this.listTarget.appendChild(empty)
    } else {
      results.forEach(result => {
        const li = document.createElement('li')
        li.className = 'px-3 py-2 cursor-pointer hover:bg-slate-700/60 transition'
        li.dataset.url = result.url
        li.addEventListener('click', () => { window.location.href = result.url })

        const top = document.createElement('div')
        top.className = 'flex items-baseline justify-between gap-2'

        const name = document.createElement('span')
        name.className = 'text-sm text-slate-200 truncate'
        name.textContent = result.name

        const badge = document.createElement('span')
        badge.className = 'shrink-0 text-[10px] uppercase tracking-wider text-slate-500'
        badge.textContent = result.type

        top.appendChild(name)
        top.appendChild(badge)
        li.appendChild(top)

        if (result.meta) {
          const meta = document.createElement('div')
          meta.className = 'text-xs text-slate-400 mt-0.5 truncate'
          meta.textContent = result.meta
          li.appendChild(meta)
        }

        this.listTarget.appendChild(li)
      })
    }

    this.dropdownTarget.classList.remove('hidden')
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

  #handleKeydown(event) {
    if (event.key === 'Escape') {
      this.#closeDropdown()
      this.inputTarget.blur()
      return
    }

    const isMac = navigator.platform.toUpperCase().includes('MAC')
    const activationKey = isMac ? event.metaKey : event.ctrlKey
    if (activationKey && event.key === 'k') {
      event.preventDefault()
      this.inputTarget.focus()
      this.inputTarget.select()
      return
    }

    if (event.key === '/' && document.activeElement !== this.inputTarget &&
        !['INPUT', 'TEXTAREA', 'SELECT'].includes(document.activeElement.tagName)) {
      event.preventDefault()
      this.inputTarget.focus()
    }
  }
}
