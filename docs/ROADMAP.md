# Roadmap

This is Ludava's **curated backlog of future project-level initiatives**, not a record of completed work or every supported game. Each entry describes why it matters, the intended experience, and what would count as done. Delete entries when finished; Git history and merged PRs provide the historical record.

New game profiles, memory fields, routine fixes, research experiments and CI results do **not** need roadmap entries unless they become a deliberate broader initiative.

## Next — Flutter Windows application

**Goal:** Replace terminal interaction for normal gameplay with a comfortable desktop GUI suitable for a laptop or a handheld gaming PC.

**Ideas:** Create `apps/ludava_app` as a Flutter Windows frontend consuming only public `ludava_sdk` capabilities. Show RPCS3 connection and active-game status, currently available fields, values and understandable errors. Support refresh/re-detection, simple value editing and reliable indication of read-only or unavailable fields. Keep the SDK as the source of process identity, session state, and write authorization. No separate game engine or duplicated frontend policy.

**Done when:** The Windows Flutter build can connect to RPCS3, detect a supported game, read Bolts, perform a guarded edit, report failures clearly, and work in a real gameplay session without terminal commands.

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
