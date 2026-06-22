import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['slide', 'indicator']

  static values = {
    index: {
      type: Number,
      default: 0
    }
  }

  connect() {
    this.showCurrentSlide()
  }

  previous() {
    this.indexValue = this.indexValue === 0 ? this.slideTargets.length - 1 : this.indexValue - 1
    this.showCurrentSlide()
  }

  next() {
    this.indexValue = this.indexValue === this.slideTargets.length - 1 ? 0 : this.indexValue + 1
    this.showCurrentSlide()
  }

  showCurrentSlide() {
    this.slideTargets.forEach((slide, index) => {
      slide.classList.toggle('hidden', index !== this.indexValue)
    })

    this.indicatorTargets.forEach((indicator, index) => {
      indicator.classList.toggle('bg-button-primary', index === this.indexValue)
      indicator.classList.toggle('bg-outline', index !== this.indexValue)
    })
  }
}