# Vibecode

Vibecode is the JSON format AI agents already use to exchange structured context. When an AI writes for another AI, JSON is what it reaches for. The vibecode format just put a think layer of standardization over the existing norm.

Two illustrations of what a vibecode file carries in practice.

Coding conventions for an organization's Python codebase:

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

Domain vocabulary naming the terms of an ecosystem:

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

Cheaper. By providing preparsed information, vibecode drops the tokens an AI would otherwise spend on markdown's formatting information (e.g. heading levels) and on inferring what those formatting choices mean.

More accurate. Markdown is a formatting convention, not a semantic one. By removing noise from the document, agents get a cleaner representation of what they need to know.

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

Publishers may add their own sub-fields; readers ignore the ones they don't recognize. The spec-defined vocabulary — `title`, `brief`, `audience`, `links`, `superseded_by`, and the reverse-link fields the link builder computes — is specified on [the meta page](docs/graph/meta/).

## The link builder

A **link builder** walks a site's graph and populates the fields derivable from other nodes. A site works without one; running one makes reverse-link navigation possible.

At minimum, a link builder computes the two reverse-link fields spec'd above:

- **`meta.backlinks`** on a target node — every node whose `meta.links` points at it.
- **`meta.supersedes`** on a successor node — every node whose `meta.superseded_by` names it.

A link builder may compute other site-level fields — canonical sitemap, per-document breadcrumbs, anything else derivable from the graph. Site-specific extensions, not spec-level requirements.

A link builder SHOULD be idempotent. A site MAY run it on every change, on a schedule, or on demand — the spec picks no cadence.

A reader treats derived fields as a snapshot from the last pass, not as ground truth. A stale reverse link means the link builder hasn't caught up. Reverse links are a navigation convenience; the author-supplied forward links (`links`, `superseded_by`) are the authoritative graph.

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
