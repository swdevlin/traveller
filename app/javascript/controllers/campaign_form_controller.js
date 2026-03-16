import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['sectorSource', 'campaignTypeHint', 'sectorSourceHint']

  connect () {
    this.refreshCampaignTypeHint()
    this.refreshSectorSourceHint()
  }

  toggleSectorSource (event) {
    const isDeepnight = event.target.value === 'deepnight_revelation'
    this.sectorSourceTarget.classList.toggle('hidden', !isDeepnight)
    this.refreshCampaignTypeHint()
  }

  refreshSectorSourceHint () {
    if (!this.hasSectorSourceHintTarget) return
    const select = this.element.querySelector('select[name*="sector_source"]')
    this.sectorSourceHintTarget.textContent = select?.selectedOptions[0]?.dataset?.hint || ''
  }

  refreshCampaignTypeHint () {
    if (!this.hasCampaignTypeHintTarget) return
    const select = this.element.querySelector('select[name*="campaign_type"]')
    this.campaignTypeHintTarget.textContent = select?.selectedOptions[0]?.dataset?.hint || ''
  }
}
