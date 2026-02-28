// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Preserve the Coloris picker across Turbo Drive navigations.
// Coloris appends its picker to <body> on DOMContentLoaded; Turbo replaces <body>
// on navigation, which destroys the picker. Transplanting it into the incoming
// body before the swap keeps the closure's internal reference valid.
document.addEventListener('turbo:before-render', (event) => {
  const picker = document.getElementById('clr-picker')
  if (picker) event.detail.newBody.appendChild(picker)
})
