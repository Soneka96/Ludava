# Roadmap

This is Ludava's **curated backlog of future project-level initiatives**, not a record of completed work or every supported game. Each entry describes why it matters, the intended experience, and what would count as done. Delete entries when finished; Git history and merged PRs provide the historical record.

New game profiles, memory fields, routine fixes, research experiments and CI results do **not** need roadmap entries unless they become a deliberate broader initiative.

## Next — Refine Flutter Windows UI and validate gameplay

**Goal:** Build a tiny, cohesive native Windows Flutter trainer for 1–5 numeric values, suitable for mouse/keyboard and the ROG Ally touchscreen.

**Ideas:** Native title with dynamic game name and no duplicated content title; compact fixed-height status/error/Refresh header; permanent right-aligned comma-formatted numeric inputs; commit when the field is intentionally left with optimistic, guarded writes and silent success; show failure in the existing header without moving controls. Add fast Flutter-only automatic value reads paused for edits, slower game identity checks, meaningful Refresh recovery, and no changes to Nocterm's manual workflow. Size window naturally for 1–5 fields, permit proportional DPI-aware scaling, remember usable position, and support the Windows touch keyboard. Add animations only after lifecycle and window correctness.

**Execution:** [16 staged, small Flutter UI tasks](tasks/flutter-ui/README.md), to start only **after PR #16 is merged**. Keep the SDK safety authority, existing Redux/GetIt/ViewModel architecture, Graphite & Teal tokens and strict test boundaries; authoritative conventions change alongside implementation, not by duplicating rules in this roadmap.

**Done when:** Editing, refresh and errors cause no layout shift; dynamic native window and keyboard work on actual Windows/Ally; automatic synchronization and optimistic writes remain safe across session changes; and the owner successfully performs a guarded Flutter read/write during a live RPCS3 session without terminal commands.

## Later — Repository presentation and branding

**Goal:** Make the project immediately understandable and pleasant to explore without turning the README into another technical reference manual.

**Ideas:** Establish a consistent visual identity/logo, improve the root README layout and quick start, and show *real* application screenshots or short GIF demonstrations once Flutter has a usable interface. Link to authoritative feature, game and build documents rather than duplicating research, offsets or transient CI counts.

**Done when:** A first-time repository visitor can quickly understand Ludava, see what using it looks like, find the build instructions and understand the project's personal-maintainer and licensing model.

## Later — Simple Windows distribution

**Goal:** Run Ludava without installing Dart, Flutter or a development toolchain on the target device.

**Ideas:** Produce ready-to-use Windows x64 ZIP artifacts containing the executable and required native libraries. Offer an uncomplicated release/download workflow with accurate setup instructions; consider an installer only if ZIP distribution proves inadequate. Reuse existing Windows build/CI machinery rather than creating a separate packaging system.

**Done when:** A Windows user can download, extract and launch the app with all required files, without building it themselves.

---

The ordering above expresses intent, not deadlines or PR numbers. Reprioritize when actual needs change; do not add completed milestones or detailed per-game evidence here.
