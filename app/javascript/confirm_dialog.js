import { Turbo } from '@hotwired/turbo-rails';

// Replaces the browser's confirm() for every `data-turbo-confirm`. Optional attributes on the
// form or submitting button: data-confirm-title, data-confirm-label (button text), and
// data-confirm-style="primary" for non-destructive actions (the default styling is danger).
function confirmDialog(message, form, submitter) {
  const read = (name) => submitter?.dataset[name] || form?.dataset[name];

  return new Promise((resolve) => {
    const dialog = document.createElement('dialog');
    dialog.className = 'confirm-dialog';
    dialog.setAttribute('aria-labelledby', 'confirm-dialog-title');

    const title = document.createElement('h2');
    title.id = 'confirm-dialog-title';
    title.className = 'confirm-dialog-title';
    title.textContent = read('confirmTitle') || 'Please confirm';

    const body = document.createElement('p');
    body.className = 'confirm-dialog-message';
    body.textContent = message;

    const cancel = document.createElement('button');
    cancel.type = 'button';
    cancel.className = 'btn';
    cancel.textContent = 'Cancel';

    const accept = document.createElement('button');
    accept.type = 'button';
    accept.className = read('confirmStyle') === 'primary' ? 'btn btn-primary' : 'btn btn-danger';
    accept.textContent = read('confirmLabel') || 'Confirm';

    const actions = document.createElement('div');
    actions.className = 'confirm-dialog-actions';
    actions.append(cancel, accept);
    dialog.append(title, body, actions);

    let result = false;
    accept.addEventListener('click', () => { result = true; dialog.close(); });
    cancel.addEventListener('click', () => dialog.close());
    // Clicks on the backdrop land on the dialog element itself.
    dialog.addEventListener('click', (event) => { if (event.target === dialog) dialog.close(); });
    dialog.addEventListener('close', () => { dialog.remove(); resolve(result); });

    document.body.appendChild(dialog);
    dialog.showModal();
    cancel.focus();
  });
}

if (Turbo.config?.forms) {
  Turbo.config.forms.confirm = confirmDialog;
} else {
  Turbo.setConfirmMethod(confirmDialog);
}
