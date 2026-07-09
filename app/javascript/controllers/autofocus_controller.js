import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    connect() {
        this.element.focus();
        const length = this.element.value.length;
        this.element.setSelectionRange(length, length);
    }
}
