import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['groups', 'output', 'groupTemplate', 'conditionTemplate'];
  static values = { fields: Array, operators: Array, operatorsForField: Object, fieldOptions: Object, initial: Object };

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

  fieldChanged(event) {
    const conditionEl = event.target.closest('[data-condition]');
    this.#updateOperatorOptions(conditionEl);
    this.#updateValuesPicker(conditionEl);
  }

  serialize() {
    const groups = [...this.groupsTarget.querySelectorAll('[data-group]')].map(groupEl => (
      [...groupEl.querySelectorAll('[data-condition]')].map(conditionEl => ({
        field: conditionEl.querySelector('[data-field]').value,
        operator: conditionEl.querySelector('[data-operator]').value,
        negate: conditionEl.querySelector('[data-negate]').checked,
        values: [...conditionEl.querySelectorAll('[data-values-picker] input:checked')].map(input => input.value)
      }))
    ));

    this.outputTarget.value = JSON.stringify({ groups });
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
    conditionEl.querySelector('[data-negate]').checked = condition.negate === true;

    groupEl.querySelector('[data-conditions]').append(conditionEl);

    this.#updateValuesPicker(conditionEl, condition.values);
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

  // The value picker is always built from the actual list of valid options
  // for the selected field (a fixed UWP code range, or — for `bases` — the
  // live Facility table), never free text, mirroring the Elm map editor.
  #updateValuesPicker(conditionEl, selectedValues = []) {
    const fieldValue = conditionEl.querySelector('[data-field]').value;
    const options = this.fieldOptionsValue[fieldValue] ?? [];
    const picker = conditionEl.querySelector('[data-values-picker]');
    const checked = new Set(selectedValues ?? []);

    picker.innerHTML = '';
    options.forEach(([value, label]) => {
      const wrapper = document.createElement('label');
      wrapper.className = 'flex items-center gap-1 cursor-pointer';

      const input = document.createElement('input');
      input.type = 'checkbox';
      input.value = value;
      input.checked = checked.has(value);
      input.className = 'accent-highlight';

      wrapper.append(input, document.createTextNode(label));
      picker.append(wrapper);
    });
  }
}
