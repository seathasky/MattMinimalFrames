# Modules

Purpose: feature-focused modules that support addon behavior but are not core frame construction.

These modules should stay scoped, reusable, and event-driven.

## Owns

- Standalone feature behaviors (for example auras, minimap integration).
- Event helpers and combat-safe execution utilities.
- Cross-cutting helpers used by frame/runtime layers when appropriate.

## Does Not Own

- Main frame build/styling primitives.
- Popup shell/page/widget implementation.
- Broad startup/profile bootstrap logic.

## Development Notes

- Prefer using existing shared module helpers before adding new utility variants.
- Keep feature boundaries clear: one module should own one concern.
- If logic becomes generic across modules, promote it to a shared helper instead of duplicating.
