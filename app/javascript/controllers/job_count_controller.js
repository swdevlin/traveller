import { Controller } from '@hotwired/stimulus'
import { createConsumer } from '@rails/actioncable'

const consumer = createConsumer()

export default class extends Controller {
    static targets = ['container', 'count']

    connect() {
        this.subscription = consumer.subscriptions.create(
          { channel: 'JobsChannel' },
          { received: (data) => this.update(data) }
        )
    }

    disconnect() {
        this.subscription?.unsubscribe()
    }

    update(data) {
        const count = Number(data?.count || 0)

        this.countTarget.textContent = String(count)

        this.containerTarget.hidden = count === 0
    }
}
