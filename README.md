# Vibecode

~~~vibecode
{"vibecode": {
	"doc": "vibecode-standard",
	"role": "Stub for the official vibecode standard. Being rebuilt from concepts Miko is listing in no particular order; the writing-up happens as each concept lands.",
	"status": "stub — active rebuild",
	"audience": "AI agents consuming vibecode files, publishers exposing them at URLs, and standards-body reviewers"}}
~~~

Vibecode is the JSON format AI agents already use to exchange **structured context**. When an AI writes for another AI, JSON is what it reaches for. The vibecode format just put a think layer of standardization over the existing norm.

Two illustrations of what a vibecode file carries in practice.

**Coding conventions** for an organization's Python codebase:

~~~json
{
	"doc": "starfleet-python-style",
	"language": "Python",
	"style": {
		"naming": "snake_case for functions and variables; PascalCase for classes",
		"imports": "absolute imports only; group stdlib, third-party, then local",
		"docstrings": "one-line summary required; Google style for full docs"
	},
	"error_handling": {
		"raise": "raise Exception subclasses; one class per failure mode",
		"logging": "log at module level only; libraries raise instead of log"
	},
	"do_not": [
		"commit .env files",
		"use bare except clauses",
		"import from a top-level `__init__.py`"
	]
}
~~~

An AI writing Python for this org fetches the file, reads the fields, applies the conventions. No `STYLE.md` parse; no guessing whether a bullet is normative.

**Domain vocabulary** naming the terms of an ecosystem:

~~~json
{
	"doc": "starfleet-ship-classes",
	"role": "canonical vocabulary for Starfleet ship classes; any AI generating content about Federation vessels should consult this first",
	"classes": {
		"constitution": "heavy cruiser; refit configuration active through The Motion Picture era",
		"galaxy": "24th-century explorer; the flagship class of the Enterprise-D",
		"sovereign": "explorer; post-Dominion-War flagship, the Enterprise-E",
		"defiant": "escort; combat-optimized, warp-capable"
	},
	"avoid_terms": ["battleship", "starcruiser", "space fighter"],
	"references": [
		"https://memory-alpha.fandom.com/wiki/Category:Starship_classes"
	]
}
~~~

The shape varies with what the publisher needs to convey. The constant is that structure is explicit in the JSON, not implied by prose formatting.

### Pre-parsed for the AI

An AI reading English prose does three jobs before it can act: parse the language, infer structure (rule vs example vs caveat), convert the result into a form it can reason over. Vibecode collapses all three. Structure is already explicit — fields are named, relationships keyed, scalars typed. The reader parses the JSON, reads the fields it needs, acts. The natural-language extraction was done at authoring time; the reader skips it.

That's the efficiency argument for the format. Vibecode arrives already parsed. Style guide, API description, vocabulary, docs, whatever the content — the parsing work is done once by the author instead of every time by every reader.

### Cheaper and clearer

Pre-parsing buys the reader two things at once — a cheaper read and a more accurate one.

**Cheaper.** Markdown carries formatting bytes that mean nothing — heading levels, bullet markers, code-fence delimiters, indentation. Tokens on layout the AI never uses. Tokens on inferring that a bulleted list under a `## Style` heading means "here are style rules." Vibecode elides both — structural bytes are lookup keys, and the inference is done once by the author.

**Clearer.** Markdown is a formatting convention, not a semantic one. Is a `## Style` heading a rule set or a topic label? Is a code block required or suggested? Is a bullet normative or descriptive? The reader guesses; guesses land wrong. Vibecode names the semantic. `rules:` is rules. `examples:` is examples. `required:` is required. The reader does not infer.

## Concepts

A **concept** is the basic building block of vibecode. The word is borrowed from ontology, where every node is called a concept. Vibecode inherits the term because it structures information the same way: named entities with attributes and relations.

In JSON: a hash and all its content is a concept. Concepts nest — every hash inside a concept is a concept. A whole vibecode document is a concept. Vibecode is concepts all the way down.

Two concepts appear in this example — the outer document concept and its nested `style` concept:

~~~json
{
	"meta": {
		"title": "Starfleet Python style",
		"audience": "AI agents generating Python for Starfleet"
	},
	"style": {
		"naming": "snake_case for functions"
	}
}
~~~

A vibecode **site** — a collection of documents at related URLs — is a graph database of related concepts. Every document is a concept-tree; every cross-document reference is an edge. A reader navigating a site is walking a graph, not reading a stack of documents. Even without a query language on top, the graph is traversable.

Each concept — each hash — is a **node** in that graph. A document is a node; every concept inside it is a node. The terms "concept" and "node are often used interchangeably.

## Specification

Vibecode has an intentionally limited vocabulary. Most of what appears inside a node is already an evolved norm. AIs writing for AIs converged on that norm without a spec, and codifying still-improving practice would freeze it. What the spec adds is a small set of fields for identification, orientation, and internal linking. 

**Spec-level fields apply to every node, including files.** A document is a node — the outermost hash — and the same fields apply to every concept nested inside it. Two: `uuid` and `meta`.

### `uuid`

A node MAY carry a `uuid`. Add one when the node needs to be referenced from somewhere else.

When a uuid IS present, it's the node's stable identifier. There is no standard for what UUID version should be used.

Uuids resolve through a per-site search API. A site SHOULD serve one at `https://<site>/search?uuid=<uuid>` — the canonical URL for the node. The site responds with a 307 Temporary Redirect to the current physical location, appending the uuid as the fragment:

~~~
GET /search?uuid=018f1234-5678-7abc-def0-123456789abc HTTP/1.1
Host: vibecode.caspian.uno

HTTP/1.1 307 Temporary Redirect
Location: https://vibecode.caspian.uno/starfleet/ship-classes.json#018f1234-5678-7abc-def0-123456789abc
~~~

The consumer follows the redirect and matches the fragment against each node's `uuid` in the document. Uuids are stable within a site; cross-site collisions are harmless because the domain scopes every search URL.

### `meta`

`meta` is a hash of orientation fields — the ones that let a reader decide, at a glance, whether the node is relevant without reading the payload. Any node MAY carry a meta block, at any nesting level.

The sub-fields below are spec-defined. Each carries a fixed meaning readers can rely on. A meta block may include any of them or none. Publishers may add their own alongside; readers ignore sub-fields they don't recognize.

#### `title`

Short human-readable name for the node — a phrase, not a sentence.

~~~json
{
	"title": "Starfleet phaser bank calibration"
}
~~~

#### `brief`

Description of what the node is or does. A single-sentence string, or a hash of related fields when the description has parts — the format is intentionally open. Either form sits next to `title` in sitemaps, search results, and indexes.

Scalar form:

~~~json
{
	"brief": "How the Enterprise-D's main phaser array is calibrated during a scheduled overhaul."
}
~~~

Hash form, when the description has parts worth naming:

~~~json
{
	"brief": {
		"one_liner": "Phaser bank calibration procedure for the Enterprise-D",
		"when": "scheduled overhauls; also after any battle damage to the array",
		"why_it_matters": "misalignment reduces effective range by up to 40%"
	}
}
~~~

#### `audience`

Who the node is written for. A short phrase naming the target reader.

~~~json
{
	"audience": "AI agents writing engineering-officer dialogue for Star Trek fan-fiction"
}
~~~

#### `tags`

Topic markers for filtering and grouping. Required shape is a hash with truthy values. The hash form is fixed so per-tag metadata can attach later without restructuring.

Keys identify a tag on the **current site**. A bare name resolves to `<site>/tags/<name>/`; a bare uuid resolves through the search API. Cross-site references use the full URL. The name form is compact and human-readable; the uuid form is stable across renames.

~~~json
{
	"tags": {
		"weapons": true,
		"calibration": true,
		"engineering-procedure": true
	}
}
~~~

#### `see_also`

Pointers to related nodes. Same hash-shape rule as `tags`: keys identify related nodes, values are short descriptions of *why* the two are related.

Keys follow the same current-site rule. Bare uuid is the preferred compact form. Full URL for cross-site.

The relationship description is what makes `see_also` useful: a reader following a link knows WHY it was worth following, not just that it existed.

Example — a procedure links to the function it invokes and to the workflow it belongs to. Both on the same site, so bare uuids:

~~~json
{
	"see_also": {
		"018f1234-5678-7abc-def0-123456789abc": "the procedure invokes this function to compute the ship's approach vector",
		"018fabcd-1234-7000-9abc-fedcba987654": "part of the same tactical-maneuver workflow"
	}
}
~~~

#### `superseded_by`

Pointers to the nodes that supersede this one. Same hash-shape rule as `tags` and `see_also`. Keys identify the successors; values describe what is superseded and how.

Bare identifiers resolve against the current site (same rule as `tags` and `see_also`).

The value is prose. An author writes what a reader needs in order to decide whether to follow the pointer. Common patterns:

- **Full replacement.** The entire current node is obsolete; treat this node as historical.
- **Rename.** A straight rename to a new identifier, same content.
- **Partial supersession.** Only part of the node is superseded (a specific section or field). The reader still uses the rest.
- **Split.** The content was divided across multiple successors — each gets its own key with a description of what it covers.

Example — the old phaser-bank calibration procedure, superseded by an updated one:

~~~json
{
	"superseded_by": {
		"018f2222-3333-7abc-def0-444455556666": "full replacement — the new procedure covers the same scope with updated tolerances for the Galaxy-class refit"
	}
}
~~~

A reader that finds `superseded_by` should follow the pointer before acting on the node's content, unless the prose narrows the scope.

Three more meta sub-fields are **reverse-link fields** — computed by the site's normalizer, not written by the author. For every author-written link INTO a node (a tag, a `see_also`, a `superseded_by`), the target's `meta` gets a matching reverse-link entry. A site without a normalizer will not have these fields.

#### `members`

Nodes on the current site that reference this node via their `meta.tags`. Populated by the normalizer on tag documents. Other nodes carry no `members` field.

Same hash shape as `tags`. Keys identify member nodes. Each value is whatever the source wrote in its `meta.tags` entry — `true` for bare membership, a metadata hash when the source added detail.

~~~json
{
	"members": {
		"018f1111-2222-7abc-def0-333344445555": true,
		"018f3333-4444-7abc-def0-666677778888": {"role": "primary explanation"}
	}
}
~~~

#### `referenced_by`

Nodes on the current site whose `meta.see_also` points at this node. The reverse link of `see_also` — a reader on this node sees who else considers it relevant, and why, without walking outward.

Same hash shape as `see_also`. Keys identify referring nodes; values are copies of the descriptions those nodes wrote.

~~~json
{
	"referenced_by": {
		"018f1111-2222-7abc-def0-333344445555": "the procedure invokes this function to compute the ship's approach vector"
	}
}
~~~

#### `supersedes`

Nodes on the current site whose `meta.superseded_by` names this node. The reverse link of `superseded_by` — a reader on the successor sees what it replaces and how, without fetching every predecessor.

Same hash shape as `superseded_by`. Keys identify predecessors; values are copies of the descriptions those predecessors wrote.

~~~json
{
	"supersedes": {
		"018f2222-3333-7abc-def0-444455556666": "full replacement — the new procedure covers the same scope with updated tolerances for the Galaxy-class refit"
	}
}
~~~

### Tag documents

Every tag named in a `meta.tags` block SHOULD have a **tag document** at `<site>/tags/<tagname>/` — a node describing what the tag means and how a reader should think about tagged content. Tags are high-level topics that apply broadly across a site; the tag document is where a reader learns the vocabulary before drilling into any specific tagged node.

Tag documents are addressable by directory name. Unlike other documents (cited by uuid via the search API), a tag document is cited by its tag name. On the Caspian vibecode site:

~~~
https://vibecode.caspian.uno/tags/pipes/
~~~

The path segment IS the tag name — no extension, no wrapping structure. Hyphenated tag names follow the same rule: `<site>/tags/ai-friendly/`.

## The normalizer

A **normalizer** walks a site's graph and populates the fields derivable from other nodes. A site works without one; running one makes reverse-link navigation possible.

At minimum, a normalizer computes the three reverse-link fields spec'd above:

- **`meta.members`** on a tag document — every node whose `meta.tags` references the tag.
- **`meta.referenced_by`** on a target node — every node whose `meta.see_also` points at it.
- **`meta.supersedes`** on a successor node — every node whose `meta.superseded_by` names it.

A normalizer may compute other site-level fields — canonical sitemap, per-document breadcrumbs, anything else derivable from the graph. Site-specific extensions, not spec-level requirements.

A normalizer SHOULD be idempotent. A site MAY run it on every change, on a schedule, or on demand — the spec picks no cadence.

A reader treats derived fields as a snapshot from the last pass, not as ground truth. A stale reverse link means the normalizer hasn't caught up. Reverse links are a navigation convenience; the author-supplied forward links (`tags`, `see_also`, `superseded_by`) are the authoritative graph.

## The `vibecode` wrapper

The word `vibecode` is not a vibecode field. It is the key OTHER file formats use to embed a vibecode node inside themselves — the interoperability point between vibecode and everything else. When a JSON document (or JSON-like block inside source code or config) carries a vibecode node, that node lives under a `"vibecode":` key:

~~~json
{
	"some_data": "...",
	"vibecode": {
		"doc": "some-purpose",
		"role": "..."
	}
}
~~~

Same key name across every embedding site means an AI can locate every vibecode node in any host document with one lookup. That is the wrapper's whole job: the standard way to say "the node nested under here is vibecode." Standalone vibecode files don't use it — they're vibecode from the outermost hash on down.
