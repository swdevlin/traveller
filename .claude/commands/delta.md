# Delta — Add Release Note

Add a new release note entry for today's changes.

## Steps

1. **Determine today's date code**
   - Today's date is available in your memory as `currentDate`
   - Calculate the ordinal day of the year (e.g. 14 March 2026 = day 073)
   - The date code format is `YYYY.DDD` (zero-padded to 3 digits)
   - The filename format is `YYYY-DDD.md` (e.g. `content/releases/2026-073.md`)

2. **Review recent work**
   - Look at `git diff HEAD` and recent commits (`git log --oneline -10`) to understand what has changed since the last release note
   - Check the most recent existing file in `content/releases/` for style reference

3. **Write the release note**
   - Create `content/releases/YYYY-DDD.md` with this structure:
     ```
     ---
     date_code: 'YYYY.DDD'
     ---

     ### Title

     Description in British English, written in third person, present tense.
     Describe what the feature or change does from the user's perspective.
     ```
   - Use `###` headings for each distinct change
   - Write in British English, third person, present tense
   - Focus on user-visible changes — skip internal refactors unless they have UX impact
   - If there are multiple unrelated changes, use multiple `###` sections in the one file
   - Do not include the date in the body — it comes from the front matter
   - The content should read like a 1960s computer manual, technical, and have a sci-fi feel to it

4. **Draft a Bluesky post**
   - Write a short summary of the delta (diff) suitable for posting to Bluesky
   - Plain language, not the 1960s-manual voice — keep it a straightforward summary, not a blow-by-blow of every detail
   - Stay well under Bluesky's 300-character limit
   - If there are multiple unrelated changes, summarise the headline one(s) rather than listing every change

5. **Confirm** — show the user the release note file content and the Bluesky post, and ask if they'd like any changes before finishing
