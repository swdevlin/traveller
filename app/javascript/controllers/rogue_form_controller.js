import {Controller} from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["typeSelect", "section"];
    connect() {
        this.update();
    }

    typeChanged() {
        this.update();
    }

    update() {
        const type = this.typeSelectTarget?.value;
        this.sectionTargets.forEach((el) => {
            const matches = el.dataset.type === type;
            el.classList.toggle('hidden', !matches);

            el.querySelectorAll("input, select, textarea").forEach((input) => {
                input.disabled = !matches;
            });
        });
    }
}

