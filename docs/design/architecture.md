# Architecture

- **Serializable state:** All gameplay-relevant state can be serialized and restored at any stable
  point without changing the resulting game.
- **Deterministic simulation:** Given the same initial state, game and mod versions, seed, and
  ordered actions at the same simulation times, the game produces the same result. All random
  chance comes from explicitly seeded generators whose gameplay-relevant state is serializable;
  mod behavior that participates in the simulation must obey the same deterministic contract.
- **Perfect replays:** A replay records or identifies everything needed to reconstruct its starting
  conditions, including the exact game and mod versions, seed, and every accepted action with its
  authoritative order and simulation time. Running the replay through the game core must reproduce
  the original game exactly.
- **Presentation-independent game core:** Game rules and state transitions run in a headless
  server/core with no presentation responsibilities. UIs, CLIs, APIs, and agent-facing interfaces
  are interchangeable clients that use the same commands and observations.
- **Low-coupling core library:** Authoritative game functionality is packaged as a reusable library
  behind a narrow, explicit interface. Presentation, transport, storage, and executable entry
  points may depend on the core library; the core library must not depend on them.
- **Data-driven and moddable:** Game content, rules, behavior, and UI composition should be defined
  as external data wherever practical rather than hardcoded into the engine. Mods are a first-class
  input and may add or replace content, behavior, and presentation features. Players can select a
  set of mods, have their data, rules, and behavior loaded into the runtime, and then start a game;
  changing that mod set while a game is running is not required.
- **Shared rules for every player:** Human players and agents—whether operating through an API,
  CLI, or UI—interact with the same game rules and state model. Presentation layers must not
  contain authoritative gameplay logic.
- **Dev scenarios:** High-level gameplay regression tests called dev scenarios exercise the public
  game-core interface deterministically. The same scenario can run headlessly or be loaded and
  visualized in a game client without changing its setup, actions, or assertions.
- **Weekly simulation time:** The simulation advances in discrete weekly ticks rather than as a
  continuous, delta-time simulation.
- **Real-time pacing with pause:** The game is presented in real time with pause. Real-world time
  controls when weekly ticks are requested; it is distinct from simulation time.
- **Top-level structure:** `clients/` contains multiple clients, such as the API, CLI, and UI;
  `server/` contains the server; and `engine/` contains the economic simulator as a library.
- **Per-game metrics:** Every game starts its own ephemeral metrics stack so agents and humans can
  easily inspect what is happening inside the engine and elsewhere in the game.

## Decisions still open

- Serialization and data file formats.
- Replay format, compatibility, and version-retention policy.
- The boundary and communication protocol between clients and the game core.
- The core library's implementation language and public interface.
- How mods express complex behavior.
- How moddable UI definitions are represented and executed.
- How dev scenarios are authored, discovered, and selected in game clients.
- Whether remote/networked play will be supported.
- Mod isolation, permissions, compatibility, and load-order rules.
