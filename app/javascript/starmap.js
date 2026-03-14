document.addEventListener('turbo:load', () => {
  const node = document.getElementById('root')

  if (!node || !window.Elm || !window.Elm.Main) {
    return
  }

  const serverFlags = JSON.parse(node.dataset.starmapFlags || '{}')
  const upperLeft = JSON.parse(localStorage.getItem('upperLeftHex') ?? 'null')
  const hexSize = JSON.parse(localStorage.getItem('hexSize') ?? '40')

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
      localStorage.setItem('upperLeftHex', JSON.stringify(value))
    })
  }

  if (elm.ports.storeHexSize) {
    elm.ports.storeHexSize.subscribe(value => {
      localStorage.setItem('hexSize', JSON.stringify(value))
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