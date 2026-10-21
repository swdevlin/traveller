---
name: Summary Section — Right Sidebar
description: Alternative plan to display the key-data summary in the right sidebar column alongside the existing subsector map, rather than inline at the top of the main content.
type: project
---

## Plan: Summary Section — Right Sidebar

### Overview

The stellar objects show page (`stellar_objects/show.html.erb`) already uses `_two_column_page` with a `page-side` column (380px wide) that currently holds the subsector map. This plan puts the summary data at the top of that sidebar, above the map.

The main content area is unchanged from today's layout (the location info moves into Orbital Data as described in the inline plan, but no summary block appears inline). The sidebar becomes the quick-reference panel.

---

### How the sidebar is populated

`stellar_objects/show.html.erb` renders `@stellar_object` (the type partial) and then populates `:page_side`. Because the summary content varies by type, the show view will attempt to render a per-type `_sidebar_summary` partial by convention:

```erb
<%= content_for :page_side do %>
  <%= render "#{@stellar_object.class.name.underscore.pluralize}/sidebar_summary",
             stellar_object: @stellar_object
             if lookup_context.template_exists?("#{@stellar_object.class.name.underscore.pluralize}/sidebar_summary") %>
  <% if subsector %>
    <%= render 'subsectors/map_embed', subsector: subsector, highlight: parsec.id %>
  <% end %>
<% end %>
```

This is zero-config: a type that has a `_sidebar_summary` partial gets it; types without one just show the map as before.

---

### Step 1 — New helper: `atmosphere_survival_requirement`

Same as the inline plan. Add to `app/helpers/stellar_objects_helper.rb`.

| Code | Result |
|---|---|
| 0, 1 | Vacc Suit |
| 2 | Respirator (or Respirator, Filter if tainted) |
| 3 | Respirator |
| 4, 5, 6, 8, 13 | None (or Filter if tainted) |
| 7, 9 | Filter |
| 10 | Air Supply |
| 11 | Vacc Suit |
| 12 | HEV Suit |
| 14 | Respirator |
| 15 | Varies |

---

### Step 2 — Sidebar layout considerations

`page-side` is `w-full md:w-[380px]`. With 380px, the summary grid should be `grid-cols-2` (two data_blocks per row), giving up to 5 rows for 9–10 fields. The subsector map sits below it.

On mobile (`< md`), `page-body` is `flex-col`, so the sidebar stacks below the main content — the summary is not visible until the user scrolls past the detail sections. This is a trade-off vs. the inline plan where the summary is always first.

A slim `space-y-4` wrapper in the sidebar holds: [summary block] + [map].

---

### Step 3 — Sidebar summary partials for world types

**File:** `app/views/terrestrial_planets/_sidebar_summary.html.erb`  
**File:** `app/views/planetoids/_sidebar_summary.html.erb`  
**File:** `app/views/moons/_sidebar_summary.html.erb`

All three are identical in structure, differing only in the local variable name. Use a shared `_world_sidebar_summary` partial and thin wrappers, or duplicate if simpler.

Layout within the partial — a subsection header "Summary" followed by `grid grid-cols-2 gap-3`:

| Field | Source |
|---|---|
| UWP | `stellar_object.uwp` (mono) |
| Starport | `stellar_object.starport_code` (identifier, only if present) |
| Gravity | `stellar_object.gravity` + `g` |
| Temperature | `format_temperature_celsius` + `°C` |
| Atmosphere | `atmosphere_survival_requirement(code, tainted:)` |
| Population | `population_range(population_code)` with identifier |
| Government | code + type |
| Law Level | code + weapons |
| Tech Level | identifier badge |

The jump shadow distance (a single number) can also appear here as it's key data for approach planning.

---

### Step 4 — Sidebar summary partials for other types

**Gas Giant** — `app/views/gas_giants/_sidebar_summary.html.erb`  
Fields (`grid-cols-2`): Code, Diameter, Mass, Rotation

**Planetoid Belt** — `app/views/planetoid_belts/_sidebar_summary.html.erb`  
Fields (`grid-cols-2`): Resource Rating, Bulk, Span, Significant Bodies

**Star** — `app/views/stars/_sidebar_summary.html.erb`  
Fields (`grid-cols-2`): Spectral Type + Class, Temperature, Mass, HZCO, Jump Shadow

**Simple types** (comet, gas cloud, etc.) — no sidebar summary partial needed; map shows as today.

---

### Step 5 — Move location info into Orbital Data

Same as the inline plan: the top location grid (Orbiting, Star System, Subsector, Sector, Allegiance) moves into the Orbital Data section for all types. The jump shadow table stays inside the Orbital Data section (unlike the inline plan where it moves to the top).

For rogues (no star, no Orbital Data section): keep a minimal location grid at the top of the main content column.

---

### Step 6 — Update `stellar_objects/show.html.erb`

Add the convention-based render to `:page_side`:

```erb
<%= content_for :page_side do %>
  <div class="space-y-4">
    <% summary_partial = "#{@stellar_object.class.name.underscore.pluralize}/sidebar_summary" %>
    <% if lookup_context.template_exists?(summary_partial, [], true) %>
      <%= render summary_partial, stellar_object: @stellar_object %>
    <% end %>
    <% if subsector %>
      <%= render 'subsectors/map_embed', subsector: subsector, highlight: parsec.id %>
    <% end %>
  </div>
<% end %>
```

No changes needed to `_two_column_page` or the CSS — `page-side` is already 380px.

---

### Trade-offs vs. inline plan

| | Inline | Sidebar |
|---|---|---|
| Mobile visibility | Summary always first | Summary below main content |
| Desktop layout | Summary takes width of main column | Summary in fixed 380px sidebar |
| Impact on main content | Removes top grids, adds summary block | Minimal — main content unchanged except location→orbital move |
| Subsector map | Unchanged | Sidebar now holds both summary and map |
| Breadth of change | All 15 partials restructured | 15 partials get location change; 4–6 get new sidebar partial |

---

### Files to create
- `app/views/application/_world_sidebar_summary.html.erb` (shared base)
- `app/views/terrestrial_planets/_sidebar_summary.html.erb`
- `app/views/planetoids/_sidebar_summary.html.erb`
- `app/views/moons/_sidebar_summary.html.erb`
- `app/views/gas_giants/_sidebar_summary.html.erb`
- `app/views/planetoid_belts/_sidebar_summary.html.erb`
- `app/views/stars/_sidebar_summary.html.erb`

### Files to modify
- `app/helpers/stellar_objects_helper.rb` — add `atmosphere_survival_requirement`
- `app/views/stellar_objects/show.html.erb` — add convention-based sidebar summary render
- All 15 stellar object show partials — move location grid into Orbital Data section
