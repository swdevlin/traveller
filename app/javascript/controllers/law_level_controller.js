import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["code", "subClassification"]

  sync() {
    const value = this.codeTarget.value
    this.subClassificationTargets.forEach(select => { select.value = value })
  }
}
