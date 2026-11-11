# Roadmap

This is Ludava's **curated backlog of future project-level initiatives**, not a record of completed work or every supported game. Each entry describes why it matters, the intended experience, and what would count as done. Delete entries when finished; Git history and merged PRs provide the historical record.

New game profiles, memory fields, routine fixes, research experiments and CI results do **not** need roadmap entries unless they become a deliberate broader initiative.

## Next — Remove production verification-status bureaucracy

**Goal:** A game profile and field registered on `main` is an owner-approved, working read-and-write capability, not a candidate whose approval is tracked in code.

**Ideas:** Remove `VerificationStatus` (`experimental`, `researchConfirmed`, `verified`, `unsupported`, and `none`), the separate `readStatus` and `writeStatus` on `GameProfile` and `GameField`, and their evidence-based `canRead`/`canWrite` gates. Do not replace them with a different approval flag or status system. Research and test incomplete mappings on development branches; do not merge a new game field into `main` until the owner confirms both a successful Ludava read and a guarded write with the intended in-game result, using **either** the TUI **or** Flutter. One frontend is sufficient because both share the SDK. Keep sources, observed build identities, and limitations in the game research records. Retain all runtime safety protections: current process/session and executable identity, guest base, bounds, preliminary reads, complete native transfer, matching read-back, and meaningful read/write operation results. This initiative does not remove runtime failure statuses.

**Done when:** Production profiles contain only owner-approved working fields without verification/approval status metadata; the SDK and its tests no longer depend on that metadata; authoritative development and architecture rules are updated in their own documents; and no runtime memory or identity safeguard is weakened.

## Next — Refine Flutter Windows UI and validate gameplay

**Goal:** Make the existing Flutter desktop app a cohesive, compact, native-feeling Windows utility, suitable for a laptop and a handheld gaming PC.

**Ideas:** Improve visual hierarchy, spacing, alignment, content density, and the relationship between the title bar, connection status, active-game header, Refresh action, and dynamic field rows; remove unnecessary empty space. Redesign inline numeric editing so the value, editor, apply, cancel, errors, and focus behave coherently without moving or resizing the field row, including at small window sizes. Investigate native Windows 11 maximize-button hover and Snap Layouts integration instead of showing only an ordinary Flutter tooltip; preserve native minimize/maximize/restore/close behavior. Keep the existing Graphite & Teal tokens, Comfortable style preset, a single Refresh action, stable geometry, touch and physical keyboard usability, and SDK/Redux/ViewModel boundaries. Do not start a new UI framework or theme architecture.

**Done when:** Normal, editing, and error states are visually coherent and free of overflow or layout shifts at 520 × 360 and 480 × 340 logical pixels with one or multiple fields; title-bar hover and window controls behave appropriately on Windows 11; mouse, keyboard, and touch input work; and the Flutter app successfully detects a supported game and performs a guarded read/write during a live RPCS3 session without terminal commands.

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
