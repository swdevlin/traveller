# Project Memory

## Form Validation Errors

Display validation errors **under each field** using:
```erb
<%= render 'application/field_error', form: f, attribute: :field_name %>
```
Defined in `app/views/application/_field_error.html.erb`. Shows orange text with a warning icon. See `app/views/star_systems/new.html.erb` for usage examples.

## Form CSS Classes

- `edit-label` — field label styling (uppercase, small, slate-400)
- `edit-base` — input styling (rounded, dark bg, slate border)

## Link Styling

Links should **not** have an underline by default; underline only on hover. Use `class='no-underline hover:underline'`. Pill links use `class='pill no-underline hover:underline'`.

## Table Conventions

- Numeric columns: `text-right` on both `<th>` and `<td>`
- Icon-only columns (Charts, Reference): `text-center` on `<th>`, `text-center` on `<td>`; use `flex items-center justify-center gap-3` inside the cell when grouping multiple icons

## JavaScript Style

Always use semicolons in JS code.

## Hex Orientation

- [Hexes are always flat-top](../memory/feedback_hex_orientation.md) — first vertex at 0° (rightmost); never pointy-top.

## Notes Fields

`notes` columns are CommonMark (Markdown). Display with a markdown renderer; edit with a markdown-aware textarea (not plain text).

## Release Note Style

See `memory/feedback_release_notes_tone.md` — 1960s technical manual, sci-fi register. Titles as protocol names; "parameter/directive/classification" not "flag/setting/option". Canonical example: `content/releases/2026-081.md`.

## Stellar Object Edit Pattern

- `StellarObjectsController` handles edit/update polymorphically for all STI types
- `edit.html.erb` dispatches to `#{type_collection}/_form.html.erb` (e.g. `comets/_form.html.erb`)
- Strong params use `@stellar_object.class.permitted_params` — override in subclass
- Data fields (JSON column) use `form.fields_for :data, (obj.data || {})` pattern
- **Must pass explicit `value:` for data fields** — the hash object doesn't respond to accessor methods, so `df.number_field :m_type, value: stellar_object.m_type` is required
- For checkboxes: `df.check_box :field, { checked: obj.field, class: '...' }, 'true', 'false'`
- No controller/route changes needed to add edit forms for new types
