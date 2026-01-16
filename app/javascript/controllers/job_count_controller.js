import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["count", "container"];
    static values = { url: String, interval: { type: Number, default: 7000 } };

    connect() {
        this.poll();
        this.timer = setInterval(() => this.poll(), 7000);
    }

    disconnect() {
        if (this.timer) {
            clearInterval(this.timer);
        }
    }

    async poll() {
        try {
            const response = await fetch(this.urlValue);
            if (response.ok) {
                const data = await response.json();
                this.updateDisplay(data.count);
            }
        } catch (error) {
            // Silently ignore fetch errors
        }
    }

    updateDisplay(count) {
        if (!this.hasContainerTarget || !this.hasCountTarget) return;

        if (count > 0) {
            this.countTarget.textContent = count;
            this.containerTarget.hidden = false;
        } else {
            this.containerTarget.hidden = true;
        }
    }
}
