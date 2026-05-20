import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['ship', 'jumpRange']

  shipChanged() {
    const option = this.shipTarget.selectedOptions[0]
    const jump   = option?.dataset?.jumpDrive
    if (jump) this.jumpRangeTarget.value = jump
  }

  jumpRangeChanged() {
    this.shipTarget.value = ''
  }

  preventModalClose(event) {
    event.stopPropagation()
  }
}
