# Rulebook Search

Referees can search across every rulebook their campaign has enabled for a term (e.g. "jump
drive") and get back a ranked list of rulebooks, printed page numbers, and highlighted
excerpts.

Rulebooks are uploaded once into a **global catalog** (admin-managed, at `/admin/rulebooks`) —
shared across every campaign, since referees search the same physical rulebooks regardless of
which campaign they're running. But **not every referee owns every book**, so each campaign
separately controls which catalog books it actually uses via its **Library** page (Data Cores →
Library, `/c/:campaign_slug/library`). A referee enables the books their campaign uses, and can
further mark a subset of those as visible to **players** — anonymous, not-logged-in visitors
(this app has no separate player-account system; "not logged in" *is* the player role). Search
itself lives at `/c/:campaign_slug/rulebooks/search`, and from a "Rulebooks" toolbar icon in the
Elm starmap app: the campaign's own referee sees results from every enabled book; a player sees
only the enabled-and-player-searchable subset.

PDFs are uploaded once, at import time, through the admin UI — never retained afterward. Only
extracted page text, cleaned/searchable text, and metadata are stored; the original PDF is
deleted from the server as soon as it's been parsed and the pages are populated (whether the
import succeeds or fails). Keep your source PDFs in your own private archive — the app is not
where they live long-term.

## Install the PDF extractor locally

The importer shells out to `libexec/extract_rulebook.py`, a small Python script built on
[PyMuPDF4LLM](https://pymupdf.readthedocs.io/en/latest/pymupdf4llm/), for column-aware text
extraction and heading detection. Production runs this from a dedicated, pinned venv baked into
the `Dockerfile` (`/opt/rulebook-extractor`, versions pinned in `requirements-rulebooks.txt`).

For local development, create your own venv and point `RULEBOOK_PYTHON` at it:

```bash
python3 -m venv .venv-rulebooks
.venv-rulebooks/bin/pip install -r requirements-rulebooks.txt
```

Then set `RULEBOOK_PYTHON=/absolute/path/to/.venv-rulebooks/bin/python` in your `.env` (loaded
automatically via `dotenv-rails`). If `RULEBOOK_PYTHON` isn't set, the app falls back to plain
`python3` on `PATH` — fine if you've installed the pinned packages there instead, but a dedicated
venv is recommended so your system Python is untouched.

Verify with:

```bash
python3 libexec/extract_rulebook.py test/fixtures/files/sample_rulebook.pdf | head -c 200
```

## Create a rulebook

Create a `Rulebook` record via `/admin/rulebooks/new` (admin only). A PDF file is **required**
at creation — attach it in the same form. Set:

- **Title** / **short title** / **edition** / **publication year** / **category**
- **PDF page offset** — see below; get this right *before* creating, since it determines the
  default printed page number for every page that doesn't have an explicit override.

Creating the record and importing the attached PDF happen together as one step: saving the form
queues the import as a background job immediately, using the uploaded file. The uploaded PDF is
deleted from the server once the job finishes (success or failure) — nothing to clean up
afterward, and nothing lingers if the import fails partway through.

## Set the PDF page offset

The PDF's page index (its position when opened in a plain viewer) almost never matches the
number printed on the page — covers, blank pages, and roman-numeral front matter all shift
things. The relationship is:

```text
printed_page_number = pdf_page_number - page_number_offset
```

To find the right offset: open the PDF, find any page where you can read the printed page
number, and note its PDF page index. Then:

```text
page_number_offset = pdf_page_number - printed_page_number
```

For example, if PDF page 8 is printed as page 3, `page_number_offset = 8 - 3 = 5`.

This offset is only the *default* — individual pages can still override it (see
[Correcting individual page numbers](#correcting-individual-page-numbers) below).

## Import a PDF

There are two ways to import, depending on context:

**From the admin UI** (`/admin/rulebooks/:id`, "Start Import") — upload the PDF via the browser.
The upload is staged temporarily on the server, processed as a background job, and deleted
afterward regardless of outcome. This is the normal path for one-off imports, and it **always**
reprocesses the upload — even a byte-identical re-upload of the current file — so it's also how
you force a reimport (e.g. after an extractor/pipeline change, or edited header/footer patterns).
The rulebook's `id` never changes across reimports; uploading a corrected/updated PDF on an
existing rulebook's show page reindexes that same record in place.

**From the command line** — for scripted or bulk imports, or when you'd rather not use the
browser:

```bash
bin/rails "rulebooks:import[<id-or-short_title>,/absolute/path/to/rulebook.pdf]"
```

`<id-or-short_title>` can be either the rulebook's numeric ID or its `short_title`. Unlike the
web UI, the CLI task reads a real path on the server and **never deletes it** — it's your own
file, kept in your private archive, and the task only ever reads it. This is safe to rerun — if
the file's checksum is unchanged and the rulebook is already `ready`, it's a no-op.

If an import fails partway through (a corrupt page, a missing binary), the rulebook is left
`failed` with a diagnostic message — it is never left looking `ready` with only some pages
imported.

## Force a reimport

The admin UI's "Start Import" always forces a reimport (see above) — there's no separate
unchanged-checksum no-op check to skip. The CLI task, by contrast, defaults to skipping an
unchanged file (see above) and needs an explicit opt-in to force a reprocess:

**From the command line** — add `FORCE=true`:

```bash
FORCE=true bin/rails "rulebooks:import[<id-or-short_title>,/absolute/path/to/rulebook.pdf]"
```

Needed after replacing the source PDF with a corrected version (a new printing, an errata
release, etc.) — a plain (non-forced) reimport of an unchanged file is a no-op.

## Enabling a rulebook for a campaign

Importing a PDF adds it to the global catalog, but a campaign won't see it in search until its
referee opts in. From within a campaign, go to Data Cores → Library
(`/c/:campaign_slug/library`) to see every globally-available rulebook and toggle:

- **Enabled** — this campaign's referee (and, once also marked player-searchable, players) can
  find this book in search.
- **Player Searchable** — of the enabled books, which ones are also visible to anonymous
  players. A book can't be player-searchable without also being enabled; turning "Enabled" off
  clears "Player Searchable" too.

Only the campaign's own referee can reach or change this page.

## Correcting individual page numbers

Not every page is a simple offset away from its printed number: covers, inserted maps, blank
pages, and renumbered sections all need manual handling. Use the compact page-mapping table at
`/admin/rulebooks/:id/rulebook_pages/mapping` to spot-check many pages at once — it shows the
PDF page, the default printed page (from the offset), any override, and the effective printed
page side by side.

Open an individual page from that table to:

- Set an explicit **printed page override** (a specific number, independent of the offset), or
- Mark the page **unnumbered** (covers, blank pages, inserted maps — anything with no real
  printed page number). Unnumbered pages show as "Unnumbered page" in search results instead
  of a number.

A page can have an override *or* be marked unnumbered, never both — the form (and the
database) both enforce this.

## Rebuild search vectors

Rulebook PDF extraction is often noisy — repeated headers/footers, page numbers bleeding into
the text, purchaser watermarks. Each rulebook has a configurable list of header/footer removal
patterns (regular expressions, admin-editable, one per line) applied during text
normalization.

After editing those patterns, re-run normalization without re-reading the PDF:

```bash
bin/rails "rulebooks:rebuild_search_vectors[<id-or-short_title>]"
# or, to rebuild every rulebook:
bin/rails rulebooks:rebuild_search_vectors
```

This re-runs the normalizer over each page's already-extracted raw text and recomputes the
search index — the same action is available as a button on the rulebook's admin page. The raw
extracted text (`body`) is always preserved separately from the cleaned/searchable text
(`normalized_body`), specifically so normalization can be redone — or diagnosed — without a
full reimport. (This is unaffected by the PDF itself being deleted after import — normalization
only ever needs the already-extracted text, never the original file.)

## Hiding a rulebook from search entirely

Toggle **Searchable** off from the admin rulebook list or show page (`/admin/rulebooks`) to
remove a rulebook from the global catalog's search candidates entirely — no campaign can enable
it while it's off, and it disappears from every campaign's search immediately, without deleting
it or its imported pages. This is a global, admin-only kill switch, separate from a campaign's
own per-book "Enabled" toggle on its Library page.