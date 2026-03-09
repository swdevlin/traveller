// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import { Turbo } from "@hotwired/turbo-rails"
import "controllers"

Turbo.StreamActions.select_new_ship = function() {
  const select = document.getElementById('jump_log_ship_id')
  if (!select) return
  const option = this.templateContent.querySelector('option').cloneNode(true)
  const insertBefore = Array.from(select.options).find(o => o.value && o.text > option.text)
  if (insertBefore) {
    select.insertBefore(option, insertBefore)
  } else {
    select.appendChild(option)
  }
  select.value = option.value
  select.dispatchEvent(new Event('change', { bubbles: true }))
}

// Preserve the Coloris picker across Turbo Drive navigations.
// Coloris appends its picker to <body> on DOMContentLoaded; Turbo replaces <body>
// on navigation, which destroys the picker. Transplanting it into the incoming
// body before the swap keeps the closure's internal reference valid.
document.addEventListener('turbo:before-render', (event) => {
  const picker = document.getElementById('clr-picker')
  if (picker) event.detail.newBody.appendChild(picker)
})
