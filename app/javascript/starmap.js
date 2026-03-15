document.addEventListener('turbo:load', () => {
  const node = document.getElementById('root')

  if (!node || !window.Elm || !window.Elm.Main) {
    return
  }

  const serverFlags = JSON.parse(node.dataset.starmapFlags || '{}')
  const slug = serverFlags.campaignSlug || 'default'
  const upperLeftKey = `upperLeftHex_${slug}`
  const hexSizeKey = `hexSize_${slug}`
  const upperLeft = JSON.parse(localStorage.getItem(upperLeftKey) ?? 'null')
  const hexSize = JSON.parse(localStorage.getItem(hexSizeKey) ?? '40')

  const elm = window.Elm.Main.init({
    node,
    flags: {
      upperLeft,
      hexSize,
      ...serverFlags
    }
  })

  if (elm.ports.storeInLocalStorage) {
    elm.ports.storeInLocalStorage.subscribe(value => {
      localStorage.setItem(upperLeftKey, JSON.stringify(value))
    })
  }

  if (elm.ports.storeHexSize) {
    elm.ports.storeHexSize.subscribe(value => {
      localStorage.setItem(hexSizeKey, JSON.stringify(value))
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
})