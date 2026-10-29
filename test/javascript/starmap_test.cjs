const { test } = require('node:test')
const assert = require('node:assert/strict')
const { readFileSync } = require('node:fs')
const vm = require('node:vm')

const source = readFileSync('app/javascript/starmap.js', 'utf8')
  .replace("import { applyTheme } from 'theme'", '')

function loadMap(href, flags, saved = new Map()) {
  const listeners = {}
  const ports = {}
  let initFlags
  const node = { dataset: { starmapFlags: JSON.stringify(flags) } }
  const window = {
    location: { href },
    history: {
      state: { navigation: 'preserved' },
      replaceState(state, title, url) {
        this.state = state
        window.location.href = url
      }
    },
    Elm: { Main: { init({ flags }) {
      initFlags = flags
      return { ports: Object.fromEntries(
        ['storeInLocalStorage', 'storePanOffset', 'storeHexSize'].map(name =>
          [name, { subscribe(callback) { ports[name] = callback } }])
      ) }
    } } }
  }
  vm.runInNewContext(source, {
    window, URL, HTMLElement: class {},
    customElements: { get() { return true } },
    document: {
      getElementById() { return node },
      addEventListener(name, callback) { listeners[name] = callback }
    },
    localStorage: {
      getItem(key) { return saved.get(key) ?? null },
      setItem(key, value) { saved.set(key, value) }
    }
  })
  listeners['turbo:load']()
  return { window, node, ports, flags: initFlags }
}

test('entry coordinates apply once; refresh restores the newly saved viewport', () => {
  const saved = new Map()
  const first = loadMap('https://example.test/c/demo/starmap?cx=10&cy=20&other=keep#map',
    { campaignSlug: 'demo', centerOn: [10, 20] }, saved)
  assert.equal(JSON.stringify(first.flags.centerOn), '[10,20]')
  assert.equal(first.window.location.href, 'https://example.test/c/demo/starmap?other=keep#map')
  assert.deepEqual(first.window.history.state, { navigation: 'preserved' })

  first.ports.storeInLocalStorage([100, 200])
  first.ports.storePanOffset([0, 0])
  first.ports.storeHexSize(60)
  const refreshed = loadMap(first.window.location.href,
    JSON.parse(first.node.dataset.starmapFlags), saved)
  assert.equal(refreshed.flags.centerOn, null)
  assert.equal(JSON.stringify(refreshed.flags.upperLeft), '[100,200]')
  assert.equal(JSON.stringify(refreshed.flags.panOffset), '[0,0]')
  assert.equal(refreshed.flags.hexSize, 60)
})

test('ordinary map loads preserve the URL', () => {
  const href = 'https://example.test/c/demo/starmap?other=keep#map'
  const result = loadMap(href, { campaignSlug: 'demo' })
  assert.equal(result.window.location.href, href)
  assert.equal(result.flags.centerOn, null)
})
