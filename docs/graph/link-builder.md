# Link builder

~~~vibecode
{"vibecode": {
	"doc": "vibecode-standard-link-builder",
	"role": "Vibecode spec page describing the link builder — the program that walks a graph in one pass and populates every field derivable from other nodes: `tgt` on each link, `backlinks`, `supersedes`, and the graph-root index files. Covers discovery, URL derivation, the authoritative list of generated fields, determinism, idempotency, and the conditions that fail the build.",
	"status": "draft — generalized from the normalizer that currently builds vibecode.caspian.uno"
}}
~~~

A **link builder** walks a graph and populates the fields derivable from other nodes. Authors write concepts and the links between them; the builder resolves those links into addresses, writes the reverse direction, and regenerates the graph-root indexes.

It runs over the whole graph in one pass. There is no incremental bookkeeping, no per-file invocation, and no state carried between runs — everything the builder writes is recomputed from the graph as it currently stands.

A graph works without one. Running one is what makes [internal consistency](./#internal-consistency) achievable and backlink navigation possible.

## What it is not

The builder is not a scaffolder. It does not create nodes, does not template empty concepts, and does not decide what fields a concept should carry. A new document starts as `{}` and the author fills it in. Building is a separate step from authoring.

It is not a validator of content, either. It checks the things it needs in order to do its own job — that references resolve, that identifiers are unique, that it is not about to overwrite something an author wrote. It has no opinion on whether a `brief` is any good.

## Discovery

One traversal from the graph root, found by the [`vibecode.root`](./file-structure.md) marker. Every JSON document under that root is part of the graph.

**The walk follows symlinks.** A graph often stitches together content whose canonical home is elsewhere — a document may live with the project it documents and appear in the graph tree at a publishing location. The builder follows the link and edits the real file; the canonical home stays where it is. A walk that sees only the graph's own directories would silently miss part of the graph, so symlink support is a requirement rather than a convenience.

## URL derivation

A document's address comes from its position in the tree, never from a field inside it. A document at `<path>/index.json` is served at `<graph-root>/<path>/`. The document at the root is served at the root.

Nothing in a document says where the document lives. That is what lets a file move without any edit to its own contents — the builder recomputes every address on the next run.

## What it generates

This table is authoritative. Everything not listed here is author-controlled and passes through untouched. A builder that modifies something absent from this table has a bug.

| Field | Location | Source |
| :--- | :--- | :--- |
| `tgt` on each link | every node carrying `meta.links` | the target node's `meta` and its position in the tree |
| `meta.backlinks` | every node some link points at | collected by walking every node's `meta.links` |
| `meta.supersedes` | every node named by a `superseded_by` | collected by walking every node's `meta.superseded_by` |
| `/sitemap.json` | graph root | walked from every document in the graph |
| `/uuids.txt` | graph root | walked from every concept carrying a `uuid` |

### `tgt` on each link

For every entry in a node's [`meta.links`](./links.md), the builder resolves the UUID key and writes the `tgt` hash beside the author's `rel`.

`tgt` is rebuilt from the target on every run, not merged with what was there before. A target whose `brief` changed yesterday has its new `brief` in every link pointing at it after the next build — copies never drift from the original, because they are never preserved.

A UUID belonging to another graph cannot be resolved to a path; the builder has no knowledge of how another graph arranges its files. Those entries get the target graph's resolver address and nothing more.

### `meta.backlinks`

The reverse direction of the same data. For every link the builder resolves, it writes a matching entry on the target recording the source. See [backlinks](./backlinks.md) for the entry format.

Backlinks are regenerated wholesale, never merged. A link an author deleted leaves no backlink behind after the next run.

### `meta.supersedes`

The reverse of `meta.superseded_by`, so a reader arriving at a successor sees what it replaces without fetching every predecessor.

### Graph-root indexes

[`sitemap.json`](./file-structure.md) and [`uuids.txt`](./uuids.md) are projections of the tree, rebuilt from scratch on every run and never merged with prior state. A hand-authored entry in either file is discarded on the next build. Editing them by hand is a stop-gap for when the builder is not running; the durable fix is always a build.

Every qualifying document appears. There is no opt-out — a document missing from the sitemap is a builder bug or a failed requirement, not a preference.

## Determinism

The walk is depth-first and alphabetized within each directory, and every generated collection is emitted in that order. Two runs over an unchanged graph produce byte-identical files.

The builder never writes a timestamp, a run counter, a generated-by comment, a version stamp, or any other value that changes between invocations. Anything that varies run to run would make every build a diff, which defeats reviewing what actually changed.

## Idempotency

A build over an already-built graph is a no-op. Every file on disk already matches what the builder would write.

That property is the test: when a run stops changing anything, the graph is fully built. It also means a build is safe to run at any time, on every change, on a schedule, or on demand — the spec picks no cadence, because no cadence can produce a wrong result.

## What it fails on

The builder fails loud and reports **every** problem it found in one pass before exiting non-zero. It does not stop at the first error. Each report names the file and the specific problem, so a fix-one-find-another cycle never happens.

Conditions that fail a build:

- **Malformed JSON.** A document does not parse.
- **Duplicate UUID.** Two concepts in the graph carry the same `uuid`. The graph's UUID space has to be unique for the resolver and `uuids.txt` to mean anything.
- **Dangling reference.** A `meta.links` key or a `meta.superseded_by` key names a UUID that exists nowhere in the graph. This is the dead-link condition the [consistency contract](./#internal-consistency) exists to prevent, caught at build time rather than by a reader.
- **Author-written builder field.** A document supplies a `tgt`, a `backlinks`, or a `supersedes` of its own. These are the builder's to write; an author value is a sign of a misunderstanding worth surfacing rather than silently overwriting.

An empty document (`{}`) or one still mid-draft is not a failure. It is skipped from the indexes and picked up once it has enough content to index. Mid-drafting is a valid state.

## Reserved fields

A field the spec has named but not yet defined behavior for is accepted without error and acted on in no way. The builder neither validates it beyond its presence nor emits it anywhere.

This is what lets authors start using a field before its behavior is settled, and lets the spec adopt it later without invalidating documents already carrying it.
