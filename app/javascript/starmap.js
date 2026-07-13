import { applyTheme } from 'theme'

document.addEventListener('turbo:load', () => {
  const node = document.getElementById('root')

  if (!node || !window.Elm || !window.Elm.Main) {
    return
  }

  const serverFlags = JSON.parse(node.dataset.starmapFlags || '{}')
  const slug = serverFlags.campaignSlug || 'default'
  const upperLeftKey = `upperLeftHex_${slug}`
  const panOffsetKey = `panOffset_${slug}`
  const hexSizeKey = `hexSize_${slug}`
  const viewModeKey = `viewMode_${slug}`
  const journeyStateKey = `journeyState_${slug}`
  const displayModeKey = `displayMode_${slug}`
  const regionDisplayKey = `regionDisplay_${slug}`
  const sectorLinesKey = `showSectorLines_${slug}`
  const subsectorLinesKey = `showSubsectorLines_${slug}`
  const backgroundNamesKey = `showBackgroundNames_${slug}`
  const jumpLogFillKey = `showJumpLogFill_${slug}`
  const highlightRulesKey = `highlightRules_${slug}`
  const routePlanKey = `routePlan_${slug}`
  const hiddenJumpRouteIdsKey = `hiddenJumpRouteIds_${slug}`
  const upperLeft = JSON.parse(localStorage.getItem(upperLeftKey) ?? 'null')
  const panOffset = JSON.parse(localStorage.getItem(panOffsetKey) ?? 'null')
  const hexSize = JSON.parse(localStorage.getItem(hexSizeKey) ?? '40')
  const viewMode = localStorage.getItem(viewModeKey) ?? null
  const journeyState = localStorage.getItem(journeyStateKey) ?? null
  const displayMode = localStorage.getItem(displayModeKey) ?? null
  const regionDisplay = localStorage.getItem(regionDisplayKey) ?? null
  const showSectorLines = JSON.parse(localStorage.getItem(sectorLinesKey) ?? 'null')
  const showSubsectorLines = JSON.parse(localStorage.getItem(subsectorLinesKey) ?? 'null')
  const showBackgroundNames = JSON.parse(localStorage.getItem(backgroundNamesKey) ?? 'null')
  const showJumpLogFill = JSON.parse(localStorage.getItem(jumpLogFillKey) ?? 'null')
  const highlightRules = JSON.parse(localStorage.getItem(highlightRulesKey) ?? '[]')
  const routePlan = JSON.parse(localStorage.getItem(routePlanKey) ?? 'null')
  const hiddenJumpRouteIds = JSON.parse(localStorage.getItem(hiddenJumpRouteIdsKey) ?? '[]')

  const elm = window.Elm.Main.init({
    node,
    flags: {
      upperLeft,
      panOffset,
      hexSize,
      viewMode,
      journeyState,
      displayMode,
      regionDisplay,
      showSectorLines,
      showSubsectorLines,
      showBackgroundNames,
      showJumpLogFill,
      highlightRules,
      routePlan,
      hiddenJumpRouteIds,
      centerOn: null,
      ...serverFlags
    }
  })

  if (elm.ports.storeInLocalStorage) {
    elm.ports.storeInLocalStorage.subscribe(value => {
      localStorage.setItem(upperLeftKey, JSON.stringify(value))
    })
  }

  if (elm.ports.storePanOffset) {
    elm.ports.storePanOffset.subscribe(value => {
      localStorage.setItem(panOffsetKey, JSON.stringify(value))
    })
  }

  if (elm.ports.storeHexSize) {
    elm.ports.storeHexSize.subscribe(value => {
      localStorage.setItem(hexSizeKey, JSON.stringify(value))
    })
  }

  if (elm.ports.storeViewMode) {
    elm.ports.storeViewMode.subscribe(value => {
      localStorage.setItem(viewModeKey, value)
    })
  }

  if (elm.ports.storeJourneyState) {
    elm.ports.storeJourneyState.subscribe(value => {
      localStorage.setItem(journeyStateKey, value)
    })
  }

  if (elm.ports.storeDisplayMode) {
    elm.ports.storeDisplayMode.subscribe(value => {
      localStorage.setItem(displayModeKey, value)
    })
  }

  if (elm.ports.storeRegionDisplay) {
    elm.ports.storeRegionDisplay.subscribe(value => {
      localStorage.setItem(regionDisplayKey, value)
    })
  }

  if (elm.ports.storeSectorLines) {
    elm.ports.storeSectorLines.subscribe(value => {
      localStorage.setItem(sectorLinesKey, JSON.stringify(value))
    })
  }

  if (elm.ports.storeSubsectorLines) {
    elm.ports.storeSubsectorLines.subscribe(value => {
      localStorage.setItem(subsectorLinesKey, JSON.stringify(value))
    })
  }

  if (elm.ports.storeBackgroundNames) {
    elm.ports.storeBackgroundNames.subscribe(value => {
      localStorage.setItem(backgroundNamesKey, JSON.stringify(value))
    })
  }

  if (elm.ports.storeJumpLogFill) {
    elm.ports.storeJumpLogFill.subscribe(value => {
      localStorage.setItem(jumpLogFillKey, JSON.stringify(value))
    })
  }

  if (elm.ports.storeHighlightRules) {
    elm.ports.storeHighlightRules.subscribe(value => {
      localStorage.setItem(highlightRulesKey, JSON.stringify(value))
    })
  }

  if (elm.ports.storeRoutePlan) {
    elm.ports.storeRoutePlan.subscribe(value => {
      localStorage.setItem(routePlanKey, JSON.stringify(value))
    })
  }

  if (elm.ports.storeHiddenJumpRouteIds) {
    elm.ports.storeHiddenJumpRouteIds.subscribe(value => {
      localStorage.setItem(hiddenJumpRouteIdsKey, JSON.stringify(value))
    })
  }

  if (elm.ports.navigateToUrl) {
    elm.ports.navigateToUrl.subscribe(url => {
      window.open(url, '_blank');
    })
  }

  if (elm.ports.navigateToUrlSameTab) {
    elm.ports.navigateToUrlSameTab.subscribe(url => {
      window.location.href = url;
    })
  }

  if (elm.ports.setTheme) {
    elm.ports.setTheme.subscribe(theme => {
      applyTheme(theme)
    })
  }

  if (elm.ports.toggleDialog) {
    elm.ports.toggleDialog.subscribe(id => {
      const dialog = document.querySelector(`#${id}`)

      if (!dialog) {
        console.error(`Dialog with id ${id} not found`)
        return
      }

      if (dialog.open) {
        dialog.close()
      } else {
        dialog.showModal()
      }
    })
  }

  document.addEventListener('keydown', (e) => {
    if (e.key !== '/') return;
    const tag = document.activeElement.tagName.toUpperCase();
    if (['INPUT', 'TEXTAREA', 'SELECT'].includes(tag)) return;
    e.preventDefault();
    const wrapper = document.getElementById('starmap-search');
    const input = (wrapper && wrapper.querySelector('input')) || node.querySelector('input[type="text"]');
    if (input) input.focus();
  });
})