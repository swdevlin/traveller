import { Controller } from '@hotwire/stimulus'

export default class extends Controller {
  start () {
    document.body.style.cursor = 'wait'
  }
}
