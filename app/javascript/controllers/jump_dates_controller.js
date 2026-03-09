import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['departYear', 'departDay', 'arriveYear', 'arriveDay']

  connect() {
    const arriveFilled = this.arriveYearTarget.value || this.arriveDayTarget.value;
    if (!arriveFilled) {
      this.departChanged();
    }
  }

  departChanged() {
    const year = parseInt(this.departYearTarget.value)
    const day = parseInt(this.departDayTarget.value)
    if (isNaN(year) || isNaN(day)) return

    const total = day + 7
    if (total > 365) {
      this.arriveYearTarget.value = year + 1
      this.arriveDayTarget.value = total - 365
    } else {
      this.arriveYearTarget.value = year
      this.arriveDayTarget.value = total
    }
  }
}
