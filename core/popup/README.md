# Popup

Purpose: configuration UI (window shell, navigation, pages, tabs, and reusable widgets).

This folder owns how settings are presented and edited.

## Owns

- Popup window lifecycle, layout shell, navigation, and scrolling.
- Page composition for unit frames, party/raid, tools, profiles, and class/auras/power sections.
- Shared popup constants/helpers and reusable control widgets.
- Header/footer chrome and popup-specific dialogs.

## Does Not Own

- Final runtime application of frame behavior logic.
- Core frame construction primitives.
- Profile bootstrap/migration logic.

## Development Notes

- Reuse shared popup controls from `shared/` and `widgets/` before creating one-off controls.
- Keep page files focused on UI composition; call into existing MMF APIs for behavior/state changes.
- Prefer simple, modular sections over large monolithic page functions.
