# Runtime

Purpose: startup, saved variables, profile state, compatibility shims, and shared runtime helpers.

This folder loads early and is the foundation for the rest of the addon.

## Owns

- Saved variable defaults and normalization.
- Profile resolution and active profile application.
- Startup refresh/migration flow.
- Compatibility gates and common runtime utilities.
- Console command wiring.

## Does Not Own

- Building unit frame visuals.
- Per-frame update/render behavior.
- Popup UI widget/layout implementation.

## Development Notes

- Reuse existing helpers before adding new ones, especially from `utilities.lua`, `profiles.lua`, and `config.lua`.
- Keep migration/normalization logic centralized instead of duplicating fixes in feature files.
- When adding a new persisted setting, update defaults and migration/refresh paths together.
