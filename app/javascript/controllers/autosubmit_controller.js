import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static values = {delay: Number };

    connect() {
        this.delay = this.hasDelayValue ? this.delayValue : 100;
        this.timer = null;
    }

    queue() {
        clearTimeout(this.timer);
        this.timer = setTimeout(() => {
            this.element.requestSubmit();

        }, this.delay);
    }
}
