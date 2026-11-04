# Contributing to Ludava

**Current phase:** documentation and research. Do not add application code, memory mappings or supported-build claims before the research handoff is accepted and the licensing policy has been decided.

## Working agreement

- Use a dedicated branch and focused pull request for each task.
- Record **problem, evidence, proposed change, verification, limitations and acceptance criteria**.
- Favor clear names, small interfaces, explicit dependencies and straightforward implementation over speculative abstractions.
- Test a behavior in the component that owns it. Mock/fake dependencies when testing consumers; do not duplicate low-level tests across the application.
- Include targeted integration tests for component wiring, error propagation and important safety boundaries.
- Real-game compatibility requires reproducible observations on a specified game/build and RPCS3 version; mocked tests alone do not establish it.
- Treat failed and partial reads as errors. Never allow unsupported or unverified writes.
- Avoid copying or mechanically translating other projects' code or data without a provenance and license review.

## Pull request checklist

1. Scope and explicit non-goals.
2. Evidence and sources, with what remains uncertain.
3. Automated tests actually run, and their results.
4. Windows/RPCS3 validation, or explicit acknowledgement that it is pending.
5. Safety, error behavior and save-backup precautions if writes are involved.
6. Draft status until applicable acceptance criteria pass.

Documentation-only changes do not require RPCS3 testing, but must not assert compatibility.

## License

The repository has no chosen license yet. Do not assume public visibility grants permission to reuse source code. Resolve licensing before adding outside contributions or releasing binaries.
