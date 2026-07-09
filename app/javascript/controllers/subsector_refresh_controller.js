import { Controller } from '@hotwired/stimulus'
import { createConsumer } from '@rails/actioncable'

export default class extends Controller {
  static values = { subsectorId: Number }
  static targets = ['frame', 'map']

  connect() {
    this.channel = createConsumer().subscriptions.create(
      { channel: 'SubsectorChannel', id: this.subsectorIdValue },
      {
        received: (data) => this.handleMessage(data)
      }
    )
  }

  disconnect() {
    if (this.channel) {
      this.channel.unsubscribe()
    }
  }

  handleMessage(data) {
    if (data.event === 'populating' || data.event === 'finished') {
      this.#reloadFrame()
    }
    if (data.event === 'finished') {
      this.#reloadMap()
    }
  }

  #reloadFrame() {
    this.frameTargets.forEach(frame => {
      const src = frame.getAttribute('src')
      if (src) {
        frame.src = ''
        frame.src = src
      }
    })
  }

  #reloadMap() {
    this.mapTargets.forEach(obj => {
      const url = obj.data
      if (url) {
        obj.data = ''
        obj.data = url
      }
    })
  }
}
