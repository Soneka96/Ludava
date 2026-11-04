# Development policy — personal project

Ludava is a **personal project maintained solely by Soneka96**. The owner does not solicit or accept external source-code contributions, unsolicited patches, feature implementations, or third-party pull requests.

Public visibility is for transparency and viewing, not an invitation to contribute or a grant of an open-source license. See [LICENSE](../LICENSE). GitHub platform rights and applicable legal exceptions still apply.

## Internal development workflow

The project's own development work follows these rules:

1. One focused task per development branch and pull request.
2. Each task records problem, evidence, implementation scope, test results and limitations.
3. Test behavior where it belongs using fake or mocked dependencies; exercise a small set of important integrations.
4. Do not label a game/build compatible without reproducible real-game validation.
5. No unverified memory writes. Unknown builds remain unsupported.
6. Prefer simple, well-separated responsibilities and incremental refactors.

These rules are internal quality standards; they are **not** contributor instructions or an invitation to submit changes.

## Third-party research and licensing

Ludava is intended as an independently implemented project. Historical research may be cited, but do not copy or mechanically translate copyright-protected source or curated data without checking its terms and obtaining any necessary permission. Credits and licensing requirements of third-party materials remain applicable.
