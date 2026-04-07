# Frame Factory

Purpose: create and style addon-owned unit frames and expose shared frame construction/update APIs.

This folder is the single source for how MMF frames are built and skinned.

## Owns

- Frame creation/bootstrap flow.
- Positioning, dragging, and reset behavior.
- Health/power/castbar/text/icon/indicator construction.
- Shared update APIs used by runtime and frame behavior modules.

## Does Not Own

- Event routing and high-level frame behavior policy.
- Popup page logic and settings UI controls.
- Profile persistence logic.

## Development Notes

- Prefer extending existing factory APIs (`public_api.lua`, `update_api.lua`, `positioning_api.lua`, `icons_api.lua`) before adding parallel paths.
- Keep rendering/build concerns here; keep game-state decisions in `core/frames` or `core/modules`.
- Avoid duplicating offset/layout logic that already exists in `positioning*` and `castbar_offsets*`.
