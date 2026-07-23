import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['ship', 'jumpRange', 'mDrive']

  shipChanged() {
    const option = this.shipTarget.selectedOptions[0]
    const jump   = option?.dataset?.jumpDrive
    const mDrive = option?.dataset?.mDrive
    if (jump) this.jumpRangeTarget.value = jump
    if (mDrive) this.mDriveTarget.value = mDrive
  }

  jumpRangeChanged() {
    this.shipTarget.value = ''
  }

  mDriveChanged() {
    this.shipTarget.value = ''
  }
}
