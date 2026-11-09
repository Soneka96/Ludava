# Documentation and convention maintenance

Use this guide when creating, updating, organizing, or retiring project documentation and engineering conventions. See [architecture](ARCHITECTURE.md) for system boundaries, [development](DEVELOPMENT.md) for source practices, and [testing](TESTING.md) for testing standards.

## Documentation ownership and upkeep

- Keep one authoritative home per rule or fact; link to it elsewhere. `ARCHITECTURE.md` owns package/feature architecture; `DEVELOPMENT.md` owns development workflow and source style; `TESTING.md` owns shared test practices; this document owns documentation upkeep and rules for maintaining conventions; Flutter conventions own Redux-specific contracts; `features/` describe behavior; `guides/` own operating/build instructions; `games/` own research; `ROADMAP.md` owns future initiatives.
- Keep README as an introduction and navigation entrypoint. Do not maintain competing convention summaries there.
- Update docs when behavior, public interfaces, supported games, research conclusions, architecture, or instructions change. Do not update them just to record commits, tests, or CI runs. Keep meaningful historical observations; remove duplicated or volatile status metadata.
- Make additions self-contained. Keep each game's research in its game record and shared Collection evidence in `games/collection.md`; do not maintain a hand-written game index. General architecture may explain evidence rules but does not duplicate hashes or addresses.
- Keep `ROADMAP.md` to meaningful future initiatives with a goal, scope, and done condition. Remove completed initiatives instead of retaining PR or test history.
- Update only the document that owns a changed fact: feature mechanisms in `features/`, game/build findings in `games/`, build instructions in `guides/`, and future work in the roadmap. Do not edit unrelated files just to synchronize status summaries.
- GitHub Actions is authoritative for current CI status. Permanent docs may describe validation categories and link to [Actions](https://github.com/Soneka96/Ludava/actions), but do not freeze run numbers or changing counts. PRs may record run-specific evidence.
- Record durable rules in their owning docs before implementation. When changing a rule, update its authority and linked references rather than copying competing versions.

## Writing and changing conventions

- Give each rule one authoritative home and a clear scope (repository-wide, SDK, Nocterm, Flutter, or a particular feature). The [agent entry point](../AGENTS.md) links to that home; it is not a second rulebook.
- Use short, grouped, actionable rules. State the required behavior or boundary, not a narrative of how a decision was reached. Use `MUST` or `MUST NOT` sparingly for strict safety or compatibility guarantees.
- Keep one independently understandable rule per bullet when practical. Group related constraints rather than multiplying near-duplicate prohibitions; put any essential exception beside its rule.
- Link to maintained code examples or existing contracts instead of copying long implementations into guidance. Describe how to verify non-obvious or safety-critical behavior.
- Record only durable, approved conventions as permanent guidance. Keep one-time PR scope, migration steps, temporary acceptance criteria, changing CI status, and decision history in their own task or PR records.
- When adopting a new convention, first review existing guidance for contradictions and duplication; change the owning rule and its links in the same documentation change. Retire obsolete guidance rather than leaving conflicting rules in place.
- Create a new conventions document only when a substantial independent responsibility justifies it. Do not split files simply to shorten a document, enforce arbitrary line limits, or build a rules framework for its own sake.
- Before committing, check internal links and heading anchors, review the changed-document diff, verify safety and testing requirements were not weakened, and confirm that no unrelated prose or research was rewritten.
