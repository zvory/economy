# Architecture

- **Serializable state:** All gameplay-relevant state can be serialized and restored at any stable
  point without changing the resulting game.
- **Presentation-independent game core:** Game rules and state transitions run in a headless
  server/core with no presentation responsibilities. UIs, CLIs, APIs, and agent-facing interfaces
  are interchangeable clients that use the same commands and observations.
- **Data-driven and moddable:** Game content, rules, behavior, and UI composition should be defined
  as external data wherever practical rather than hardcoded into the engine. Mods are a first-class
  input and may add or replace content, behavior, and presentation features. Players can select a
  set of mods, have their data, rules, and behavior loaded into the runtime, and then start a game;
  changing that mod set while a game is running is not required.
- **Shared rules for every player:** Human players and agents—whether operating through an API,
  CLI, or UI—interact with the same game rules and state model. Presentation layers must not
  contain authoritative gameplay logic.

## Decisions still open

- Serialization and data file formats.
- The boundary and communication protocol between clients and the game core.
- How mods express complex behavior.
- How moddable UI definitions are represented and executed.
- Whether remote/networked play will be supported.
- Mod isolation, permissions, compatibility, and load-order rules.
