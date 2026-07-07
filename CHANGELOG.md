# Changelog

All notable changes to JulsanityUI DataBars are documented here.
This project follows a simple 0.1-step versioning scheme.

## [1.7] — 2026-07-07

Per-datatext customization and more languages.

### Added
- **Customizable datatexts.** Most datatexts now have their own options, shown in
  the Behavior tab beneath the datatext and saved per slot (so two clocks can
  differ). Highlights:
  - Time: local vs. server time, 12/24-hour.
  - Coordinates: show zone, decimals.
  - System: FPS / MS / both, home vs. world latency.
  - Durability: lowest slot vs. average.
  - Gold: short numbers (485K), gold only, gold gained this session.
  - Bag Space: free vs. used, count the reagent bag.
  - Item Level: equipped vs. overall, decimals.
  - Experience: percent / current / remaining, show rested.
  - Reputation: percent / standing / value.
  - Movement Speed: decimals.
  - Friends: WoW / Battle.net / both.
  - Guild: online vs. online / total.
  - Difficulty: dungeon / raid / both, abbreviated vs. full names.
  - Great Vault: "Ready" vs. count.
  - Mythic+ Keystone: abbreviate the dungeon name.
- **Four new languages:** French, Spanish (also esMX), Italian and Portuguese (BR).

### Fixed
- The options window no longer jumps back to the top when you change a datatext;
  the scroll position is preserved.

## [1.6.1] — 2026-07-07

Polish and fixes for layout and text colouring.

### Added
- **Use Custom Text Color** — Text Color now actually recolours the datatext
  values, including the "good" state of status/standing datatexts (FPS,
  durability, reputation). Warning colours (low FPS/durability, low reputation)
  and iconic colours (gold coins, Mythic+ score rarity) are kept.
- **Difficulty** datatext: the click menu now also offers the legacy raid
  difficulties (10/25-player, Normal and Heroic).

### Changed
- Padding now adapts to the font size and its maximum was lowered to a sensible
  range, so datatext fields always stay readable.

### Fixed
- Dragging Padding could squeeze datatext fields until they vanished; they now
  stay visible at any padding value.
- Section separators no longer collapse (they keep full height) at high padding.
- Long datatext values (e.g. long specialization names) now truncate with "…"
  instead of overlapping the neighbouring fields.

## [1.6] — 2026-07-04

Quality-of-life features, its own identity, and a first-login fix.

### Added
- **About tab** documenting that this is an independent plugin for EllesmereUI
  (not part of the suite, no support in the EllesmereUI Discord), with buttons
  for CurseForge, GitHub, and an in-game Changelog viewer.
- **Section separators** — optional thin lines between datatexts, using the
  EllesmereUI accent or a custom colour.
- **Hide Prefixes** option (Behavior) to drop labels like "Dur" or "ilvl" and
  show just the value.
- The **main bar width can now span the full screen** (the limit follows your
  resolution / UI scale instead of a fixed 1200 px).

### Changed
- New first-run layout — Main bar: Friends, Difficulty, Loot Spec, Gold,
  Durability; Minimap bar: FPS, Guild.
- Friends and Guild now read as "Friends: 15" / "Guild: 2".
- Own addon icon and JulsanityUI branding colour in the addon list, to make
  clear this is a standalone plugin rather than part of EllesmereUI.
- Removed the EllesmereUI options-sidebar entry — the standalone window and the
  Options → AddOns button cover configuration.

### Fixed
- Accent colour could be wrong right after login until an option was toggled; it now updates as soon as         EllesmereUI applies the saved accent.

## [1.5] — 2026-07-01

Blizzard options integration & housekeeping.

### Added
- The addon is now registered under **Options → AddOns → "JulsanityUI
  DataBars"**, with a centered button that opens the configuration window
  (the `/jdbar` slash command still works as an additional entry point).
- `LICENSE.txt` (all rights reserved; private modifications only) including a
  third-party notice that all rights to EllesmereUI belong to its own author(s).

### Changed
- Opening the options window now automatically closes the Blizzard Settings
  window, so our window is no longer stacked behind it.

## [1.4] — 2026-07-01

Appearance.

### Added
- **Background texture** option: in addition to a background colour you can now
  pick a LibSharedMedia statusbar texture per bar (the colour tints the
  texture). "Solid Color" keeps the previous flat-colour behaviour.

## [1.3] — 2026-07-01

Multi-bar support.

### Added
- **Second bar for the minimap.** The addon now supports two independent bars
  (Main + Minimap), each with its own layout, appearance, behaviour, slots and
  anchor. The minimap bar auto-matches the minimap width and sits directly
  beneath it by default (still freely movable via EllesmereUI Unlock mode).
- Bar selector and per-bar **Enabled** toggle in the configuration window.

### Changed
- Data model, rendering, visibility, slot pools and the anchor system were
  generalised from a single bar to per-bar instances. Existing single-bar
  profiles are migrated automatically into the new structure.

## [1.2] — 2026-07-01

Cross-character gold.

### Added
- **Cross-character gold** in the Gold tooltip via Syndicator (Baganator):
  every character's gold grouped by faction (Alliance/Horde) with class-coloured
  names, per-faction subtotals, Warband bank gold and a grand total. Data is
  read live and never stored in our SavedVariables.
- **EllesmereUI Bags fallback**: when Syndicator is not installed, cross-character
  gold is read from EllesmereUI Bags' own tracker (flat, class-coloured list; no
  faction split). Falls back to the current character only if neither is present.

### Fixed
- **Warband bank gold** now uses the live game value (`C_Bank.FetchDepositedMoney`)
  and only falls back to a cached value — it was previously wrong or missing
  because Syndicator only refreshes its warband snapshot on bank access.

## [1.1] — 2026-07-01

DataText additions & fixes.

### Added
- **Difficulty** DataText showing the current dungeon and raid difficulty; click
  to change it via a native context menu.
- **Loot Spec** DataText that primarily shows the configured loot specialization
  (follows the active spec when set to "Current Specialization").
- **Specialization** DataText: right-click to choose the loot specialization;
  left-click still opens the talent/spec UI.

### Fixed
- Clickable DataTexts no longer show their hover tooltip on top of the context
  menu the click opens.
- **Durability** no longer stays stuck on "Dur --" after login; it now retries
  for a few seconds until equipped-item durability data is available.

## [1.0] — 2026-06-30

Initial release: a clean, modular, retail-only addon that displays
ElvUI-style DataTexts in a configurable bar, natively integrated with
EllesmereUI (no ElvUI dependency).

### Added
- Native DataText engine with a documented `RegisterDataText` API and a
  categorised registry.
- DataText catalog: Time, Coordinates, System (FPS/MS), Durability, Gold,
  Item Level, Experience, Movement Speed, Bag Space, Reputation, Friends,
  Guild, Mail, Mythic+ Score, Mythic+ Keystone, Great Vault, Specialization.
- Full configuration UI (Layout, Appearance, Behavior, Advanced) using
  EllesmereUI-styled widgets, in a standalone window and — when whitelisted —
  the EllesmereUI options sidebar.
- Own SavedVariables (`JulsanityDataBarsDB`) and a modular multi-profile system,
  independent of ElvUI and of EllesmereUI's profile store.
- Profile import/export (LibDeflate-compressed strings) and profile management
  (create/copy/delete/reset/switch).
- Custom anchor integrated into EllesmereUI Unlock/Edit mode (no ElvUI mover).
- Mouseover fade and combat auto-hide.
- Layout engine: horizontal/vertical orientation, growth direction, automatic
  or fixed sizing, spacing and padding.
- `/jdbar` slash command (config, reset, debug, debug dump).
- Debug logger with ring buffer.
- enUS + deDE locales.
