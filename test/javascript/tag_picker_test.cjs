const { test } = require('node:test')
const assert = require('node:assert/strict')
const { readFileSync } = require('node:fs')
const vm = require('node:vm')

const source = readFileSync('app/javascript/controllers/tag_picker_controller.js', 'utf8')
  .replace('import { Controller } from "@hotwired/stimulus"', 'class Controller {}')
  .replace('export default class', 'globalThis.TagPicker = class')

function picker(value, caret = value.length) {
  const context = { Event }
  vm.runInNewContext(source, context)
  const controller = new context.TagPicker()
  controller.tagsValue = ['Frontier', 'Research', 'Restricted', '<Research>']
  controller.suggestionTarget = { hidden: true, textContent: '' }
  controller.inputTarget = {
    value, selectionStart: caret, selectionEnd: caret,
    focus() {},
    setSelectionRange(start, end) { this.selectionStart = start; this.selectionEnd = end },
    dispatchEvent() { controller.suggest() }
  }
  controller.suggest()
  return controller
}

function tab(controller, options = {}) {
  let prevented = false
  controller.keydown({ key: 'Tab', preventDefault() { prevented = true }, ...options })
  return prevented
}

test('typing a prefix suggests an existing tag and Tab accepts it', () => {
  const controller = picker('res')
  assert.equal(controller.suggestionTarget.textContent, 'Research — Tab to accept')
  assert.equal(tab(controller), true)
  assert.equal(controller.inputTarget.value, 'Research, ')
  assert.equal(controller.inputTarget.selectionStart, 10)
  assert.equal(controller.suggestionTarget.hidden, true)
})

test('completes the current comma-separated tag while preserving other tags', () => {
  const controller = picker('Frontier, re, Custom', 12)
  assert.equal(tab(controller), true)
  assert.equal(controller.inputTarget.value, 'Frontier, Research, Custom')
})

test('does not suggest tags already assigned, ignoring case', () => {
  const controller = picker('research, re')
  assert.equal(controller.match.tag, 'Restricted')
  tab(controller)
  assert.equal(controller.inputTarget.value, 'research, Restricted, ')
})

test('unknown tags, empty input, and exact matches preserve normal Tab behavior', () => {
  for (const value of ['Custom', '', 'Research', 'Research, ']) {
    const controller = picker(value)
    assert.equal(controller.suggestionTarget.hidden, true)
    assert.equal(tab(controller), false)
    assert.equal(controller.inputTarget.value, value)
  }
})

test('Shift Tab, Escape, and composition do not accept suggestions', () => {
  const controller = picker('Re')
  assert.equal(tab(controller, { shiftKey: true }), false)
  assert.equal(tab(controller, { isComposing: true }), false)
  controller.keydown({ key: 'Escape' })
  assert.equal(tab(controller), false)
  assert.equal(controller.inputTarget.value, 'Re')
})

test('does not replace selected text or complete in the middle of a tag', () => {
  const controller = picker('Research', 3)
  assert.equal(tab(controller), false)
  controller.inputTarget.selectionEnd = 8
  controller.suggest()
  assert.equal(tab(controller), false)
})

test('click accepts suggestions and tag names are displayed as text', () => {
  const controller = picker('<')
  assert.equal(controller.suggestionTarget.textContent, '<Research> — Tab to accept')
  controller.accept()
  assert.equal(controller.inputTarget.value, '<Research>, ')
})
