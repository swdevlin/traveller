import { Controller } from '@hotwired/stimulus'
import { createConsumer } from '@rails/actioncable'

const consumer = createConsumer()

export default class extends Controller {
    static targets = ['container', 'count']
    static values = { schemaName: String }

    connect() {
        const params = { channel: 'JobsChannel' }
        if (this.schemaNameValue) {
            params.schema_name = this.schemaNameValue
        }
        this.subscription = consumer.subscriptions.create(
          params,
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
