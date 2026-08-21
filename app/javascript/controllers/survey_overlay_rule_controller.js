import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['groups', 'output', 'groupTemplate', 'conditionTemplate'];
  static values = { fields: Array, operators: Array, operatorsForField: Object, fieldOptions: Object, initial: Object };

  // Operators taking more than one value get a checkbox picker; every other
  // operator (including `between`, which takes exactly two) gets one select
  // per value — see `#updateValuesPicker`, mirroring `valuePicker` in
  // `HighlightRuleEditor.elm`.
  MULTI_VALUE_OPERATORS = ['one_of', 'has_one_of'];

  connect() {
    const groups = this.initialValue?.groups;
    if (Array.isArray(groups) && groups.length > 0) {
      groups.forEach(group => this.#renderGroup(group));
    } else {
      this.addGroup();
    }
  }

  addGroup() {
    const fragment = this.groupTemplateTarget.content.cloneNode(true);
    const groupEl = fragment.querySelector('[data-group]');
    this.groupsTarget.append(fragment);
    this.#addCondition(groupEl);
  }

  removeGroup(event) {
    event.target.closest('[data-group]').remove();
  }

  addCondition(event) {
    this.#addCondition(event.target.closest('[data-group]'));
  }

  removeCondition(event) {
    event.target.closest('[data-condition]').remove();
  }

  toggleNegate(event) {
    const conditionEl = event.target.closest('[data-condition]');
    const checked = !conditionEl.querySelector('[data-negate]').checked;
    this.setNegate(conditionEl, checked);
  }

  fieldChanged(event) {
    const conditionEl = event.target.closest('[data-condition]');
    this.#updateOperatorOptions(conditionEl);
    this.#updateValuesPicker(conditionEl);
  }

  operatorChanged(event) {
    const conditionEl = event.target.closest('[data-condition]');
    this.#updateValuesPicker(conditionEl);
  }

  serialize() {
    const groups = [...this.groupsTarget.querySelectorAll('[data-group]')].map(groupEl => (
      [...groupEl.querySelectorAll('[data-condition]')].map(conditionEl => ({
        field: conditionEl.querySelector('[data-field]').value,
        operator: conditionEl.querySelector('[data-operator]').value,
        negate: conditionEl.querySelector('[data-negate]').checked,
        values: this.collectValues(conditionEl)
      }))
    ));

    this.outputTarget.value = JSON.stringify({ groups });
  }

  // Value inputs vary by widget (a `<select>` per value for single/`between`
  // operators, checkboxes for multi-value operators) — see
  // `#updateValuesPicker` — so collection has to branch per element rather
  // than a single selector.
  collectValues(conditionEl) {
    return [...conditionEl.querySelectorAll('[data-values-picker] [data-value-input]')].flatMap(el => {
      if (el.tagName === 'SELECT') return el.value ? [el.value] : [];
      if (el.type === 'checkbox') return el.checked ? [el.value] : [];
      return [];
    });
  }

  #renderGroup(group) {
    const fragment = this.groupTemplateTarget.content.cloneNode(true);
    const groupEl = fragment.querySelector('[data-group]');
    this.groupsTarget.append(fragment);

    if (Array.isArray(group) && group.length > 0) {
      group.forEach(condition => this.#addCondition(groupEl, condition));
    } else {
      this.#addCondition(groupEl);
    }
  }

  #addCondition(groupEl, condition = {}) {
    const fragment = this.conditionTemplateTarget.content.cloneNode(true);
    const conditionEl = fragment.querySelector('[data-condition]');

    const fieldSelect = conditionEl.querySelector('[data-field]');
    this.fieldsValue.forEach(([value, label]) => fieldSelect.add(new Option(label, value)));
    fieldSelect.value = condition.field ?? this.fieldsValue[0][0];

    this.#updateOperatorOptions(conditionEl, condition.operator);
    this.setNegate(conditionEl, condition.negate === true);

    groupEl.querySelector('[data-conditions]').append(conditionEl);

    this.#updateValuesPicker(conditionEl, condition.values);
  }

  // Drives the Not toggle's checkbox + visuals together. Built by hand (matching
  // application/_boolean_toggle.html.erb's classes) rather than the shared
  // boolean-toggle Stimulus controller, since that controller only syncs its
  // visuals from a click/#set call — it can't be relied on to have connected yet
  // immediately after we clone and populate a condition from saved data.
  setNegate(conditionEl, checked) {
    const checkbox = conditionEl.querySelector('[data-negate]');
    const button = conditionEl.querySelector('[data-negate-toggle]');
    const indicator = conditionEl.querySelector('[data-negate-indicator]');

    checkbox.checked = checked;
    button.setAttribute('aria-checked', String(checked));
    button.classList.toggle('bg-toggle-on', checked);
    button.classList.toggle('bg-toggle-off', !checked);
    indicator.classList.toggle('translate-x-5', checked);
    indicator.classList.toggle('bg-toggle-knob-on', checked);
    indicator.classList.toggle('translate-x-0', !checked);
    indicator.classList.toggle('bg-toggle-knob-off', !checked);
  }

  #updateOperatorOptions(conditionEl, selectedOperator = null) {
    const fieldValue = conditionEl.querySelector('[data-field]').value;
    const operatorSelect = conditionEl.querySelector('[data-operator]');
    const current = selectedOperator ?? operatorSelect.value;
    const allowed = this.operatorsForFieldValue[fieldValue] ?? this.operatorsValue.map(([value]) => value);

    operatorSelect.innerHTML = '';
    this.operatorsValue
      .filter(([value]) => allowed.includes(value))
      .forEach(([value, label]) => operatorSelect.add(new Option(label, value)));

    if (allowed.includes(current)) operatorSelect.value = current;
  }

  // The value picker's options are always the actual list of valid values
  // for the selected field (a fixed UWP code range, or — for `bases` — the
  // live Facility table), never free text, mirroring the Elm map editor.
  #updateValuesPicker(conditionEl, selectedValues = []) {
    const fieldValue = conditionEl.querySelector('[data-field]').value;
    const operatorValue = conditionEl.querySelector('[data-operator]').value;
    const options = this.fieldOptionsValue[fieldValue] ?? [];
    const picker = conditionEl.querySelector('[data-values-picker]');
    const values = selectedValues ?? [];

    picker.innerHTML = '';

    if (operatorValue === 'between') {
      const and = document.createElement('span');
      and.className = 'text-xs text-fg-muted';
      and.textContent = 'and';

      picker.append(this.buildSelect(options, values[0]), and, this.buildSelect(options, values[1]));
    } else if (this.MULTI_VALUE_OPERATORS.includes(operatorValue)) {
      picker.append(this.buildChecklistDropdown(options, values));
    } else {
      picker.append(this.buildSelect(options, values[0]));
    }
  }

  buildSelect(options, selectedValue) {
    const select = document.createElement('select');
    select.dataset.valueInput = '';
    select.className = 'edit-base pr-8';

    options.forEach(([value, label]) => select.add(new Option(label, value, false, value === selectedValue)));

    return select;
  }

  buildChecklistDropdown(options, selectedValues) {
    const checked = new Set(selectedValues ?? []);

    const wrapper = document.createElement('div');
    wrapper.className = 'relative';
    wrapper.dataset.controller = 'dropdown';

    const button = document.createElement('button');
    button.type = 'button';
    button.dataset.action = 'dropdown#toggle';
    button.className = 'edit-base min-w-40 text-xs py-1 flex items-center justify-between gap-2 cursor-pointer';

    const summary = document.createElement('span');
    summary.className = 'truncate';
    button.append(summary);
    button.insertAdjacentHTML('beforeend', '<i class="fa-regular fa-chevron-down text-[10px] text-fg-muted"></i>');

    const menu = document.createElement('div');
    menu.dataset.dropdownTarget = 'menu';
    menu.className = 'hidden absolute left-0 top-full mt-1 z-50 min-w-40 max-h-48 overflow-y-auto space-y-1 rounded-lg border border-outline bg-dropdown shadow-xl p-2';

    const updateSummary = () => {
      const labels = options.filter(([value]) => checked.has(value)).map(([, label]) => label);
      summary.textContent = labels.length === 0 ? 'Select…' : labels.length <= 2 ? labels.join(', ') : `${labels.length} selected`;
    };

    options.forEach(([value, label]) => {
      const row = document.createElement('label');
      row.className = 'flex items-center gap-2 text-xs text-fg cursor-pointer';

      const input = document.createElement('input');
      input.type = 'checkbox';
      input.dataset.valueInput = '';
      input.value = value;
      input.checked = checked.has(value);
      input.className = 'accent-highlight';
      input.addEventListener('change', () => {
        if (input.checked) checked.add(value); else checked.delete(value);
        updateSummary();
      });

      row.append(input, document.createTextNode(label));
      menu.append(row);
    });

    updateSummary();
    wrapper.append(button, menu);

    return wrapper;
  }
}
