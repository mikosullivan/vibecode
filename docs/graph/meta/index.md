# Meta

~~~vibecode
{"vibecode": {
	"doc": "vibecode-standard-meta",
	"role": "Vibecode spec page describing the `meta` element — the hash of orientation fields any node may carry. Covers the author-written fields (`title`, `brief`, `audience`, `links`, `superseded_by`) and the reverse-link fields the link builder computes (`backlinks`, `supersedes`).",
	"status": "draft — ported from the README spec section; the relationship between `links` and the older reference fields is unsettled"
}}
~~~

`meta` is a hash of orientation fields — the ones that let a reader decide, at a glance, whether the node is relevant without reading the payload. Any node MAY carry a meta block, at any nesting level.

**`meta` is closed.** The sub-fields below are the whole vocabulary. Each carries a fixed meaning readers can rely on. A node MAY carry any of them or none, and MUST NOT put anything else under `meta`.

Whatever else a publisher wants to say goes in the body of the node, where nothing is reserved and nothing is restricted. Only two names are reserved anywhere in vibecode — `uuid` and `meta` — and the body is free of both.

Closing it is what makes `meta` readable without discovery. A consumer knows the complete set of things it can find there, and a field that is not on the list is a mistake rather than an extension. A genuinely useful new orientation field earns its way onto the list by proving itself in the body first.

## `title`

The node's name — what to call it, not what it is. A noun phrase, not a sentence.

`title` is a label: a heading, an entry in a list, or the words an agent uses when referring to the concept in its own output. Describing the node is `brief`'s job.

~~~json
{
	"title": "Starfleet phaser bank calibration"
}
~~~

## `brief`

Description of what the node is or does. A single-sentence string, or a hash of related fields when the description has parts — the format is intentionally open.

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

## `audience`

Who the node is written for. A short phrase naming the target reader.

~~~json
{
	"audience": "AI agents writing engineering-officer dialogue for Star Trek fan-fiction"
}
~~~

## `links`

References to other nodes, keyed by UUID. Each value is a hash describing the reference.

~~~json
{
	"links": {
		"018f1234-5678-7abc-def0-123456789abc": {
			"rel": "the vocabulary this document's class names come from",
			"url": "/starfleet/ship-classes.json#018f1234-5678-7abc-def0-123456789abc",
			"canonical_url": "https://vibecode.caspian.uno/uuid/018f1234-5678-7abc-def0-123456789abc"
		},
		"018f9999-aaaa-7bcd-ef01-222233334444": {
			"rel": "cites this as prior art",
			"canonical_url": "https://memory-alpha.example/uuid/018f9999-aaaa-7bcd-ef01-222233334444"
		}
	}
}
~~~

`rel` describes the kind of relationship. The other two fields are written by the link builder rather than by the author.

`canonical_url` is the target's permanent address — its graph's resolver, `https://<host>/uuid/<X>`. It stays correct for as long as the target exists, whatever happens to the file layout underneath it, and it is the form to cite or store outside the graph. Every entry carries one.

`url` is the target's direct location: a root-relative path to the file, carrying a fragment when the target is a concept nested inside a document. Following it is a single fetch, where `canonical_url` costs a redirect first. Only same-graph entries carry it — the builder knows its own graph's layout and can resolve a real path, but has no idea how another graph arranges its files. The path is root-relative so the same value works whether the graph is read as a local file tree or over HTTP.

A reader that wants the node now follows `url`. A reader that wants an address still correct a year from now keeps `canonical_url`.

See [the graph page](../) for how the builder populates these and why.

## `superseded_by`

Pointers to concepts that supersede this one.

The value can be any truthy JSON value. It is up to the author to decide the contents.

~~~json
{
	"superseded_by": {
		"018f2222-3333-7abc-def0-444455556666": "full replacement — the new procedure covers the same scope with updated tolerances for the Galaxy-class refit"
	}
}
~~~

A reader that finds `superseded_by` should follow the pointer before acting on the node's content, unless the value narrows the scope.

## `base_url`

The graph's deployed address. Carried on the home document only — it describes the graph, not the node it sits on.

~~~json
{
	"meta": {
		"base_url": "https://vibecode.caspian.uno"
	}
}
~~~

Everything the link builder writes is root-relative. `base_url` is what turns those paths into absolute, citable addresses: a node's `canonical_url` is `<base_url>/uuid/<X>`, and the graph's resolver answers at that same prefix.

A graph served from the root of a host carries just the origin. A graph deployed under a path carries the path as well — `https://example.com/docs` — and its resolver sits at `https://example.com/docs/uuid/<X>`. No trailing slash.

The home document MUST carry `base_url`. Without it a graph cannot express an absolute address, and the link builder stops rather than producing a graph whose `canonical_url` fields are quietly missing everywhere. A graph that exists only as a local file tree still declares the address it will be served at.

This requirement may be relaxed later. The case for loosening it is a graph that genuinely has no address yet — one being drafted before anyone has decided where it will live. If that turns out to matter, `base_url` becomes optional and the builder omits `canonical_url` rather than stopping.

## Reverse-link fields

Two more meta sub-fields are **reverse-link fields** — computed by the graph's link builder, not written by the author. For every author-written link INTO a node (a `links` entry, a `superseded_by`), the target's `meta` gets a matching reverse-link entry. A graph without a link builder will not have these fields.

### `backlinks`

Nodes whose `meta.links` point at this node. See [backlinks](../backlinks.md) for the entry format.

### `supersedes`

Nodes on the current graph whose `meta.superseded_by` names this node. The reverse link of `superseded_by` — a reader on the successor sees what it replaces and how, without fetching every predecessor.