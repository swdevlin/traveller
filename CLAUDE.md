# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Rails 8.1.1 application for managing Traveller RPG universe data - sectors, subsectors, star systems, and stellar objects. The app supports procedural generation of star systems via an external generator service.

The application is multi-tenant using ros-apartment. It uses path based tenancy and has a schema per tenant. Tenant is determined by Campaign, and schema_name is used for the schema name.

The application uses core Rails 8.1 for jobs and caching.

## Common Commands

```bash
# Start development server
bin/dev

# Run all tests
bin/rails test

# Run a single test file
bin/rails test test/models/star_system_test.rb

# Run a specific test by line number
bin/rails test test/models/star_system_test.rb:42

# Run linting
bundle exec rubocop

# Run security scanner
bundle exec brakeman

# Database operations
bin/rails db:migrate
bin/rails db:seed
```

## Pre-push Hooks

Overcommit runs on pre-push: RuboCop, Rails tests, Brakeman, and bundler-audit. Pre-commit hooks are disabled.

## schema.rb GIN Indexes

After running `db:migrate`, Rails regenerates `schema.rb` and strips the `opclass:` from the three trigram GIN indexes. Before running tests (or pushing), check that these three index lines include `opclass: :gin_trgm_ops`:

```ruby
t.index ["name"], name: "index_sectors_on_name_trgm", using: :gin, opclass: :gin_trgm_ops
t.index ["name"], name: "index_star_systems_on_name_trgm", using: :gin, opclass: :gin_trgm_ops
t.index ["name"], name: "index_subsectors_on_name_trgm", using: :gin, opclass: :gin_trgm_ops
```

Without `opclass: :gin_trgm_ops`, `db:test:load_schema` fails with `PG::UndefinedObject` because `pg_trgm` lives in the `shared_extensions` schema.

## Architecture

### Data Hierarchy

- **Sector** → contains 16 **Subsectors** (4x4 grid, A-P) → contains **Parsecs** (8x10 grid per subsector)
- A **Parsec** can contain a **StarSystem** and/or standalone **StellarObjects** (rogues)
- A **StarSystem** has **Stars** which orbit each other; **StellarObjects** orbit stars
- Coordinates use universal (x,y) system across all sectors

### Stellar Object STI

`StellarObject` is the base class using Single Table Inheritance. Subclasses in `app/models/`:
- Comet, GasCloud, GasGiant, GravityAnomaly, InterstellarWreck, PhantomObject, PlanetoidBelt, Planetoid, RadiationCloud, Relic, SpaceStation, TerrestrialPlanet, UnusualObject

Each stellar object must belong to either a parsec (rogue) OR an orbiting_star (in-system), never both.

### Key Domain Classes (app/domain/)

- `BuildConfigSchema` / `BuildConfigValidator` - Dry::Schema validation for YAML build configurations
- `StarSystemImporter` - imports generated systems from external service
- `Coordinate` - universal coordinate handling
- `DiceRoller` - dice rolling utilities for procedural generation

### Subsector Generation

Generation is handled asynchronously via `GenerateSubsectorJob`. The job:
1. Parses YAML build configuration
2. Calls external generator service (configured in `config.x.generator_service`)
3. Uses `StarSystemImporter` to create records from response
4. Broadcasts progress via `SubsectorChannel` (Action Cable)

Build configs support density types: DENSE, STANDARD, MODERATE, LOW, SPARSE, MINIMAL, RIFT, RIFT_FADE, DEEP_RIFT, EMPTY

### Real-time Updates

`SubsectorChannel` broadcasts generation progress events to connected clients.

## Code Style

- Uses rubocop-rails-omakase with single quotes enforced
- String literals use single quotes
- use British english
- Common filtered subsets of associations belong on the model as named methods, not inline at call sites in views or domain classes
- always use `jsonb` for JSON columns, never `json` — jsonb supports GIN indexes, the `@>` containment operator, and is more efficient on read
- indexing a jsonb field is better than extracting the value into a column
- when working with sectors, use Sector.kept except for queries that need to include deleted sectors

## Adding a New Property to a Stellar Object

When adding a new display field to any stellar object type, update all of the following:

1. **Rails show view** — add a `data_block` in the appropriate section partial
2. **Markdown export** — update the relevant presenter in `app/presenters/` (usually `markdown_presenter_base.rb`)
3. **Elm app** — update `frontend/starmap/src/Traveller/` (typically the relevant module such as `Population.elm`, `StellarObject.elm`, or `AnalysisDetail.elm`)
4. **Help screens** — update both the edit and show help partials in `app/views/help/`

## Show Page Sections

Use sections to visually group related fields on show pages. See `app/views/terrestrial_planets/_terrestrial_planet.html.erb` for canonical examples.

Render a section header using the `application/subsection` partial:

```erb
<%= render 'application/subsection', title: 'Section Name' %>
```

This renders a `.dg-subsection` div containing a `.label` div (orange, uppercase, tracked) and a `.line` div (slate horizontal rule). CSS is defined in `app/assets/tailwind/application.css` using descendant selectors `.dg-subsection .label` and `.dg-subsection .line`.

Follow it immediately with a `grid` of `data_block` partials:

```erb
<div class='grid grid-cols-1 gap-4 sm:grid-cols-4'>
  <%= render 'application/data_block', label: 'Field', value: object.field %>
</div>
```

Wrap the whole page in `<div class='space-y-6'>` so sections and grids are evenly spaced.
