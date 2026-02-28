import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['background', 'border']

  connect() {
    this.#handler = () => this.#sync()
    this.backgroundTarget.addEventListener('input', this.#handler)
  }

  disconnect() {
    this.backgroundTarget?.removeEventListener('input', this.#handler)
  }

  #sync() {
    if (this.borderTarget.value) return

    const derived = borderColourFor(this.backgroundTarget.value)
    if (!derived) return

    this.borderTarget.value = derived
    // Update Coloris's preview swatch on the border field
    this.borderTarget.dispatchEvent(new Event('input', { bubbles: true }))
  }
}

function borderColourFor(fillHex) {
  const rgb = hexToRgb(fillHex)
  if (!rgb) return null

  const lum = relativeLuminance(rgb)
  const factor = lum > 0.7 ? 0.55 : lum > 0.4 ? 0.65 : 0.75

  return rgbToHex({
    r: Math.round(rgb.r * factor),
    g: Math.round(rgb.g * factor),
    b: Math.round(rgb.b * factor)
  })
}

function hexToRgb(hex) {
  if (!hex) return null
  const s = hex.replace('#', '')
  if (!/^[0-9a-fA-F]{6}$/.test(s)) return null
  return {
    r: parseInt(s.slice(0, 2), 16),
    g: parseInt(s.slice(2, 4), 16),
    b: parseInt(s.slice(4, 6), 16)
  }
}

function rgbToHex({ r, g, b }) {
  return '#' + [r, g, b].map(v => Math.max(0, Math.min(255, v)).toString(16).padStart(2, '0')).join('')
}

function relativeLuminance({ r, g, b }) {
  return 0.2126 * srgbToLinear(r / 255) + 0.7152 * srgbToLinear(g / 255) + 0.0722 * srgbToLinear(b / 255)
}

function srgbToLinear(c) {
  return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)
}
