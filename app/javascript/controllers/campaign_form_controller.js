import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['sectorSource', 'campaignType', 'explorationToggle']

  connect () {
    if (this.hasCampaignTypeTarget) {
      this.#syncExploration(this.campaignTypeTarget.value)
    }
  }

  toggleSectorSource (event) {
    const campaignType = event.target.value
    const isDeepnight = campaignType === 'deepnight_revelation'
    this.sectorSourceTarget.classList.toggle('hidden', !isDeepnight)
    this.#syncExploration(campaignType)
  }

  #syncExploration (campaignType) {
    if (!this.hasExplorationToggleTarget) return

    const toggleElement = this.explorationToggleTarget.querySelector('[data-controller~="boolean-toggle"]')
    const toggle = this.application.getControllerForElementAndIdentifier(toggleElement, 'boolean-toggle')
    if (!toggle) return

    if (campaignType === 'deepnight_revelation') {
      toggle.set(true)
      toggle.setDisabled(true)
    } else if (campaignType === 'charted_space') {
      toggle.set(false)
      toggle.setDisabled(true)
    } else {
      toggle.setDisabled(false)
    }
  }
}
