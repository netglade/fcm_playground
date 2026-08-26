# Localization

The app supports English and Czech, switched from the translate icon in the
AppBar — System (follow the device), English, or Čeština — with the choice
persisted across launches.

## Where a string lives

`apps/fcm_app/lib/i18n/strings.i18n.csv` is the single source of truth for
both languages. The header must stay exactly `key,en,cs,(description)`: the
parentheses are load-bearing, because without them the generator reads the
fourth column as a third locale rather than as metadata, and the description
itself becomes the doc comment on the generated getter — what an IDE shows
when a widget calls it. Quote every prose cell; an unquoted comma silently
splits the row, and the failure only surfaces later, as a key that
mysteriously will not resolve.

Keys are snake_case dotted paths. Plurals are sibling rows — `key.one`,
`key.few`, `key.other` — because Czech distinguishes a `few` form (counts
2–4) that English does not; where English draws no distinction, its `few`
row deliberately repeats the `other` text rather than being left out. A key
can also have no Czech `few` row at all, where the Czech word is invariant
across every count — an absent row can be as deliberate as a present one.
Interpolation is `$name` or `${name}`, never ICU's `{name}` braces, and a `cs`
cell must never be left empty — a test fails on purpose if one is, so a
missing translation gets a red build rather than a silent fallback to
English.

## Adding one

Edit the CSV, then regenerate:

```bash
fvm dart run melos run --no-select l10n
```

Commit the regenerated `apps/fcm_app/lib/i18n/translations*.g.dart` alongside
the CSV change — the generated files are committed on purpose, so a fresh
clone can analyse and test without a codegen step. That command is not part
of the CI gate for the same reason; the cost is remembering to run it after
editing the CSV, which a coverage test catches if you forget.

## Adding a language

Nothing in the CSV names its two locales anywhere but the header row, so a
third language starts as a third column there, filled in for every row the
way `cs` is. That is only the data half: the language switcher in the AppBar
is three hardcoded menu entries (System, English, Czech, in
`apps/fcm_app/lib/pages/shell/app_shell.dart`), not a list built from
whatever the CSV contains, so a new language needs a fourth entry added
there by hand too.

## What stays English on purpose

- **The payload form's field labels**, because they mirror FCM's own REST
  field names, and translating them would break the link to Google's
  reference docs.
- **`ApiError.message` sent back from the API**, so an error can legitimately
  read half Czech, half English — accepted rather than papered over, since
  the server has no locale of its own to translate into.
- **The notification channel's name and description.** Android keeps the
  name a channel had at creation; re-labelling it on every language change
  would mean re-creating the channel, risking a reset of an importance
  setting the user chose, which lives on the channel rather than in the app.
