// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import { Turbo } from "@hotwired/turbo-rails"
import "controllers"
import "confirm_dialog"

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

function markTourCompleted(journeyName) {
  if (!journeyName) return;
  const token = document.querySelector('meta[name="csrf-token"]')?.content;
  fetch('/tour_completion', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token },
    body: JSON.stringify({ journey_name: journeyName }),
  });
}

document.addEventListener('turbo-tour:complete', (event) => {
  markTourCompleted(event.detail?.journey_name);
});

document.addEventListener('turbo-tour:skip-tour', (event) => {
  markTourCompleted(event.detail?.journey_name);
});

// Tour steps can target elements inside a closed dropdown menu. A hidden
// element has a zero-size bounding rect, so the tour tooltip would position
// itself at (0,0) instead of lining up with the target. Open any dropdown
// menu ancestor of the active step's target before the tooltip is positioned,
// and close whatever we opened once the tour moves to a different step.
let openedTourDropdownMenus = [];

function closeOpenedTourDropdownMenus() {
  openedTourDropdownMenus.forEach((menu) => {
    menu.classList.add('hidden');
    menu.closest('[data-controller~="dropdown"]')?.querySelector('[aria-expanded]')?.setAttribute('aria-expanded', 'false');
  });
  openedTourDropdownMenus = [];
}

function openDropdownAncestorsOf(target) {
  const opened = [];
  for (let node = target?.parentElement; node; node = node.parentElement) {
    if (node.matches?.('[data-dropdown-target="menu"].hidden')) {
      node.classList.remove('hidden');
      node.closest('[data-controller~="dropdown"]')?.querySelector('[aria-expanded]')?.setAttribute('aria-expanded', 'true');
      opened.push(node);
    }
  }
  return opened;
}

function revealActiveTourTarget() {
  closeOpenedTourDropdownMenus();

  const target = document.querySelector('[data-turbo-tour-active]');
  openedTourDropdownMenus = openDropdownAncestorsOf(target);
  if (openedTourDropdownMenus.length > 0) {
    target.scrollIntoView({ block: 'center', inline: 'nearest' });
    window.dispatchEvent(new Event('resize'));
  }
}

['turbo-tour:start', 'turbo-tour:next', 'turbo-tour:previous'].forEach((eventName) => {
  document.addEventListener(eventName, revealActiveTourTarget);
});

document.addEventListener('turbo-tour:complete', closeOpenedTourDropdownMenus);
document.addEventListener('turbo-tour:skip-tour', closeOpenedTourDropdownMenus);

// Preserve the Coloris picker across Turbo Drive navigations.
// Coloris appends its picker to <body> on DOMContentLoaded; Turbo replaces <body>
// on navigation, which destroys the picker. Transplanting it into the incoming
// body before the swap keeps the closure's internal reference valid.
document.addEventListener('turbo:before-render', (event) => {
  const picker = document.getElementById('clr-picker')
  if (picker) event.detail.newBody.appendChild(picker)
})
