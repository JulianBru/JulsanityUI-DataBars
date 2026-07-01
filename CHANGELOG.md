# Changelog

All notable changes to JulsanityUI DataBars are documented here.
This project follows a simple 0.1-step versioning scheme.

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
