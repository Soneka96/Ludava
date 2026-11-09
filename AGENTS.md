# Agent guidance

Read only the guidance that applies to the task:

- [Architecture](docs/ARCHITECTURE.md) owns feature boundaries, package dependencies, SDK composition, and authoritative state.
- [Development](docs/DEVELOPMENT.md) owns source style, testing, documentation upkeep, workspace commands, and development workflow.
- [Flutter architecture](docs/FLUTTER_ARCHITECTURE_CONVENTIONS.md) applies to the approved future Redux migration; the checked-in app still uses `TrainerController` until that migration is separately approved.
- For memory or game-identity work, preserve the contracts in [game detection](docs/features/game-detection.md) and [game memory](docs/features/game-memory.md). Keep build instructions, factual feature guides, and game research in their existing owners.

Each rule has one authoritative home. Update that home and link to it elsewhere; do not duplicate policy in the README or rewrite research and guides as conventions.
