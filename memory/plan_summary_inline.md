---
name: Summary Section — Inline (Top of Page)
description: Plan to add a key-data summary block at the top of each stellar object show page, above the detailed sections.
type: project
---

## Plan: Summary Section — Inline at Top of Page

### Overview

Add a summary row at the top of each stellar object show page containing the key Referee data points. Data is repeated from the detailed sections below. Below the summary sits the jump shadow table, then the existing sections. Location info (orbiting, star system, subsector, sector) moves from the current top grid into the Orbital Data section.

---

### Step 1 — New helper: `atmosphere_survival_requirement`

**File:** `app/helpers/stellar_objects_helper.rb`

New method taking atmosphere code (integer) and `tainted:` boolean, returning survival equipment required:

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

Called with `stellar_object.atmosphere&.dig('code')` and `stellar_object.atmosphere&.dig('taint').present?`.

---

### Step 2 — New shared partial: `_world_summary`

**File:** `app/views/application/_world_summary.html.erb`

Used by terrestrial planets, planetoids, and moons.

Layout: `grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-9 gap-4` with these `data_block`s:

| Field | Source |
|---|---|
| UWP | `stellar_object.uwp` (mono style) |
| Starport | `stellar_object.starport_code` (identifier badge, only if present) |
| Gravity | `stellar_object.gravity` + `g` |
| Temperature | `format_temperature_celsius` + `°C` |
| Atmosphere | `atmosphere_survival_requirement(code, tainted:)` |
| Population | `population_range(population_code)` with identifier badge |
| Government | code + type |
| Law Level | code + weapons description |
| Tech Level | identifier badge |

Government, law, tech only rendered when present.

---

### Step 3 — Type-specific summary partials

- **Gas Giant** `app/views/gas_giants/_summary.html.erb`: Code, Diameter, Mass, Rotation
- **Planetoid Belt** `app/views/planetoid_belts/_summary.html.erb`: Resource Rating, Bulk, Span, Significant Bodies
- **Star** `app/views/stars/_summary.html.erb`: Spectral Type+Subtype+Class, Temperature, Mass, HZCO, Jump Shadow
- **Simple types** (comet, gas cloud, gravity anomaly, phantom object, relic, interstellar wreck, space station, radiation cloud, unusual object): no summary partial — structural change only (location grid moves into Orbital Data)

---

### Step 4 — New page order for world types

```
[_world_summary]             ← new: key Referee fields
[jump_shadow_times]          ← moved: was inside Orbital Data
[Orbital Data section]       ← now includes Orbiting, Star System, Subsector, Sector, Allegiance at end
[Physical Data section]
[Environmental Data section]
  atmosphere grid
  hydrographics grid
[Biological Data]
[Social Data]
[Notes]
```

The two current top grids (starport/UWP/allegiance and location links) are removed — their fields are now in the summary or Orbital Data.

For rogues (no star, no Orbital Data section): a minimal location grid (Parsec, Subsector, Sector) is shown at top in place of Orbital Data.

---

### Step 4b — Page order for other types

**Gas Giant:**
```
[_summary]
[jump_shadow_times]
[Orbital Data]  ← + Orbiting, Star System, Subsector, Sector, Allegiance
[Physical Data]
[Notes]
```

**Planetoid Belt:**
```
[_summary]
[Orbital Data]  ← + Orbiting, Star System, Subsector, Sector
[Belt Composition]
[Belt Data]
[Notes]
```

**Star:**
```
[_summary]
[Stellar Properties]
[Orbital Data]  ← + Star System, Subsector, Sector
[System Data]
```

**Simple types:**
```
[Orbital Data]  ← + Orbiting, Star System, Subsector, Sector (moved from top grid)
[type-specific sections]
[Notes]
```

---

### Files to create
- `app/views/application/_world_summary.html.erb`
- `app/views/gas_giants/_summary.html.erb`
- `app/views/planetoid_belts/_summary.html.erb`
- `app/views/stars/_summary.html.erb`

### Files to modify
- `app/helpers/stellar_objects_helper.rb`
- `app/views/terrestrial_planets/_terrestrial_planet.html.erb`
- `app/views/planetoids/_planetoid.html.erb`
- `app/views/moons/_moon.html.erb`
- `app/views/gas_giants/_gas_giant.html.erb`
- `app/views/planetoid_belts/_planetoid_belt.html.erb`
- `app/views/stars/_star.html.erb`
- `app/views/comets/_comet.html.erb`
- `app/views/gas_clouds/_gas_cloud.html.erb`
- `app/views/interstellar_wrecks/_interstellar_wreck.html.erb`
- `app/views/gravity_anomalies/_gravity_anomaly.html.erb`
- `app/views/phantom_objects/_phantom_object.html.erb`
- `app/views/relics/_relic.html.erb`
- `app/views/space_stations/_space_station.html.erb`
- `app/views/unusual_objects/_unusual_object.html.erb`
- `app/views/radiation_clouds/_radiation_cloud.html.erb`
