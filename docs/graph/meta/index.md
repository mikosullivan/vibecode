# Meta

~~~vibecode
{"vibecode": {
	"doc": "vibecode-standard-meta",
	"role": "Vibecode spec page describing the `meta` element — the hash of orientation fields any node may carry. Covers the author-written fields (`title`, `brief`, `audience`, `links`, `superseded_by`) and the reverse-link fields the link builder computes (`backlinks`, `supersedes`).",
	"status": "draft — ported from the README spec section; the relationship between `links` and the older reference fields is unsettled"
}}
~~~

`meta` is a hash of orientation fields — the ones that let a reader decide, at a glance, whether the node is relevant without reading the payload. Any node MAY carry a meta block, at any nesting level.

The sub-fields below are spec-defined. Each carries a fixed meaning readers can rely on. A meta block may include any of them or none. Publishers may add their own alongside; readers ignore sub-fields they don't recognize.

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
			"rel": "reference",
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

## Reverse-link fields

Two more meta sub-fields are **reverse-link fields** — computed by the graph's link builder, not written by the author. For every author-written link INTO a node (a `links` entry, a `superseded_by`), the target's `meta` gets a matching reverse-link entry. A graph without a link builder will not have these fields.

### `backlinks`

Nodes whose `meta.links` point at this node. See [backlinks](../backlinks.md) for the entry format.

### `supersedes`

Nodes on the current graph whose `meta.superseded_by` names this node. The reverse link of `superseded_by` — a reader on the successor sees what it replaces and how, without fetching every predecessor.