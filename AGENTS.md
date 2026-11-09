# Agent guidance

Read only the authoritative guidance relevant to the task:

- [Architecture](docs/ARCHITECTURE.md): package and feature boundaries, dependency direction, SDK runtime, and safety invariants.
- [Development](docs/DEVELOPMENT.md): Dart source style, workflow, frontend UI conventions, workspace commands, and CI setup.
- [Testing](docs/TESTING.md): test ownership, naming, fixtures, synthetic data, safety regressions, and package-specific test practices.
- [Documentation](docs/DOCUMENTATION.md): document ownership, research upkeep, and how to write or change conventions.
- [Flutter architecture](docs/FLUTTER_ARCHITECTURE_CONVENTIONS.md): approved Redux/GetIt contract used by the Flutter app.
- For game identity or memory work, also read the [game detection](docs/features/game-detection.md) and [game memory](docs/features/game-memory.md) contracts. Use existing guides and individual game records for build instructions and evidence.

Apply rules within their stated scope. Update the single authoritative home of a changed rule; link to it elsewhere rather than copying it into `AGENTS.md` or the README. Keep one-time migration requirements in the task or PR.
