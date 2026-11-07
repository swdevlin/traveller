import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = [
    'sectorSource', 'campaignType', 'explorationToggle', 'slug',
    'initialSector', 'sectorSearchInput', 'sectorResultsFrame', 'sectorName', 'sectorX', 'sectorY',
    'submit'
  ]

  static values = { searchUrl: String }

  connect () {
    if (this.hasCampaignTypeTarget) {
      this.#syncExploration(this.campaignTypeTarget.value)
    }
  }

  sanitizeSlug (event) {
    const input = event.target
    const cursorFromEnd = input.value.length - input.selectionEnd
    const sanitized = input.value
      .toLowerCase()
      .replace(/[^a-z0-9-]+/g, '-')
      .replace(/-{2,}/g, '-')

    if (sanitized === input.value) return

    input.value = sanitized
    const position = Math.max(0, sanitized.length - cursorFromEnd)
    input.setSelectionRange(position, position)
  }

  toggleSectorSource (event) {
    const campaignType = event.target.value
    const isDeepnight = campaignType === 'deepnight_revelation'
    const isChartedSpace = campaignType === 'charted_space'
    this.sectorSourceTarget.classList.toggle('hidden', !isDeepnight)
    if (this.hasInitialSectorTarget) {
      this.initialSectorTarget.classList.toggle('hidden', !isChartedSpace)
    }
    this.#syncSubmitState(campaignType)
    this.#syncExploration(campaignType)
  }

  selectSectorOption (event) {
    const radio = event.target
    const kind = radio.dataset.kind

    this.sectorSearchInputTarget.disabled = kind !== 'search'

    if (kind === 'search') {
      this.sectorNameTarget.value = ''
      this.sectorXTarget.value = ''
      this.sectorYTarget.value = ''
      this.sectorSearchInputTarget.value = ''
      this.sectorSearchInputTarget.focus()
    } else {
      this.sectorSearchInputTarget.value = ''
      this.sectorXTarget.value = ''
      this.sectorYTarget.value = ''
      this.sectorNameTarget.value = kind === 'none' ? '' : radio.value
    }

    this.#syncSubmitState(this.campaignTypeTarget.value)
  }

  selectInitialSector (event) {
    const btn = event.currentTarget
    this.sectorNameTarget.value = btn.dataset.name
    this.sectorXTarget.value = btn.dataset.x
    this.sectorYTarget.value = btn.dataset.y
    this.#syncSubmitState(this.campaignTypeTarget.value)
  }

  queueSectorSearch (event) {
    clearTimeout(this.sectorSearchTimer)

    const query = event.target.value
    this.sectorSearchTimer = setTimeout(() => {
      const url = new URL(this.searchUrlValue, window.location.href)
      url.searchParams.set('q', query)
      this.sectorResultsFrameTarget.src = url.toString()
    }, 250)
  }

  #hasValidInitialSectorChoice () {
    const checked = this.element.querySelector('input[name="initial_sector_choice"]:checked')
    if (!checked) return false
    if (checked.dataset.kind === 'search') {
      return this.hasSectorNameTarget && this.sectorNameTarget.value.length > 0
    }
    return true
  }

  #syncSubmitState (campaignType) {
    if (!this.hasSubmitTarget) return

    const needsChoice = campaignType === 'charted_space'
    this.submitTarget.disabled = needsChoice && !this.#hasValidInitialSectorChoice()
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
