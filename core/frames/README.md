# Frames

Purpose: orchestrate runtime behavior for unit frames after they are constructed by `core/frame_factory`.

This folder connects events/state changes to visible frame behavior.

## Owns

- Frame visibility policy and update dispatch.
- Unit data update flow for live frames.
- Integrations tied to Blizzard party/raid frame behavior.
- Optional integrations like Clique support, range checks, and class resources.

## Does Not Own

- Low-level frame construction/styling primitives.
- Popup layout and setting control widgets.
- Generic startup/profile plumbing.

## Development Notes

- Reuse existing dispatch/update paths (`update_dispatcher.lua`, `unit_updates.lua`) before creating new loops.
- Put shared display construction in `core/frame_factory`, not here.
- Keep behavior modules focused and avoid duplicating checks already handled by visibility/update helpers.
