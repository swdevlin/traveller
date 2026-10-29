import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "suggestion"]
  static values = { tags: Array, source: String }

  focusOnOpen(event) {
    if (event.target.open) this.inputTarget.focus()
  }

  // Grids share one JSON element of tag names rather than embedding the list per row.
  get tags() {
    if (!this.hasSourceValue) return this.tagsValue;

    try {
      return JSON.parse(document.getElementById(this.sourceValue)?.textContent || '[]');
    } catch {
      return [];
    }
  }

  suggest(event) {
    this.match = null
    this.suggestionTarget.hidden = true
    if (event?.isComposing) return

    const input = this.inputTarget
    const caret = input.selectionStart
    if (caret !== input.selectionEnd) return

    const start = input.value.lastIndexOf(",", caret - 1) + 1
    const nextComma = input.value.indexOf(",", caret)
    const end = nextComma === -1 ? input.value.length : nextComma
    // Only complete a prefix at the end of the current tag.
    if (caret !== end) return

    const prefix = input.value.slice(start, end).trim().toLowerCase()
    if (!prefix) return

    const assigned = (input.value.slice(0, start) + input.value.slice(end))
      .split(",").map(tag => tag.trim().toLowerCase()).filter(Boolean)
    const tag = this.tags.find(tag =>
      tag.toLowerCase().startsWith(prefix) && !assigned.includes(tag.toLowerCase())
    )
    if (!tag || tag === input.value.slice(start, end).trim()) return

    this.match = { tag, start, end, value: input.value }
    this.suggestionTarget.textContent = `${tag} — Tab to accept`
    this.suggestionTarget.hidden = false
  }

  keydown(event) {
    if (event.isComposing) return
    if (event.key === "Escape") {
      this.dismiss()
    } else if (event.key === "Tab" && !event.shiftKey && this.match) {
      event.preventDefault()
      this.accept()
    }
  }

  keepFocus(event) {
    event.preventDefault()
  }

  accept() {
    const match = this.match
    const input = this.inputTarget
    if (!match || input.value !== match.value) {
      this.dismiss()
      return
    }

    const before = input.value.slice(0, match.start)
    const after = input.value.slice(match.end)
    const replacement = `${match.start > 0 ? " " : ""}${match.tag}`
    const suffix = after || ", "
    input.value = before + replacement + suffix
    const caret = before.length + replacement.length + (after ? 0 : suffix.length)
    input.focus()
    input.setSelectionRange(caret, caret)
    this.dismiss()
    input.dispatchEvent(new Event("input", { bubbles: true }))
  }

  dismiss() {
    this.match = null
    this.suggestionTarget.hidden = true
  }
}
