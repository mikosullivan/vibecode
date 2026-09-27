# Graph

~~~vibecode
{"vibecode": {
	"doc": "vibecode-standard-graph",
	"role": "Vibecode spec page describing the `graph` concept — a set of vibecode concepts sharing an internal-reference scope. Covers what a graph is, the home concept and self-declaration convention, UUID scoping, the graph's deployed forms (site vs local file tree), the HTTP surfaces every deployed graph exposes (`/uuid/<X>` UUID resolver and `/search` general search), and the link builder's role. Split out from the monolithic standard.md as part of breaking the spec into smaller focused pages.",
	"status": "draft — first cut of graph as a stand-alone spec page"
}}
~~~

A **graph** is a set of vibecode concepts sharing an internal-reference scope. A vibecode web site is an example of a graph. So is a single directory tree containing the same files as on the web site.

Every document in a graph is a concept-tree; every cross-document reference within the graph is an edge. A reader navigating a graph is traversing edges between nodes, not reading a stack of documents. Even without a query language on top, the graph is traversable.

## Graph root

A file-based graph SHOULD have a file named `vibecode.root` in its top directory. The file is a marker and nothing else — its contents are irrelevant, and an empty file is the normal case.

Tools find the root by walking upward from any file in the tree until they reach a directory containing `vibecode.root`. That directory is the graph root; everything under it belongs to the graph.

## UUID references

Concepts in the graph can reference each other with just a UUID:

~~~json
{
	"meta": {
		"links": {
			"018f1234-5678-7abc-def0-123456789abc": {
				"rel": "the vocabulary this document's class names come from"
			}
		}
	}
}
~~~

That is the authoring form. A built graph carries the resolved location alongside it:

~~~json
{
	"meta": {
		"links": {
			"018f1234-5678-7abc-def0-123456789abc": {
				"rel": "the vocabulary this document's class names come from",
				"url": "/starfleet/ship-classes.json#018f1234-5678-7abc-def0-123456789abc",
				"canonical_url": "https://vibecode.caspian.uno/uuid/018f1234-5678-7abc-def0-123456789abc"
			}
		}
	}
}
~~~

The UUID stays — it is the stable identifier and survives the target file moving. The `url` is maintained by the link builder: a direct pointer to the file so a reader following the edge fetches it, rather than resolving the UUID first.

## HTTP surfaces

A deployed graph exposes two HTTP surfaces on its hostname. Looking up a concept by UUID works through either one:

~~~
/uuid/018f1234-5678-7abc-def0-123456789abc
/search?uuid=018f1234-5678-7abc-def0-123456789abc
~~~

The two forms are equivalent — same lookup, same response. `/uuid/<X>` is the shorthand; `/search?uuid=<X>` is the same lookup expressed through the general query surface.

### `/uuid/<X>` — UUID resolver

The canonical resolver. Given a UUID, returns a 307 Temporary Redirect to the current physical location of the node. When the target is a nested concept inside a document, the redirect location appends the UUID as a URL fragment so browsers scroll to the right position.

~~~
GET /uuid/018f1234-5678-7abc-def0-123456789abc HTTP/1.1
Host: vibecode.caspian.uno

HTTP/1.1 307 Temporary Redirect
Location: https://vibecode.caspian.uno/starfleet/ship-classes.json#018f1234-5678-7abc-def0-123456789abc
~~~

The consumer follows the redirect and matches the fragment (when present) against each node's `uuid` in the document.

`/uuid/<X>` is the same URL shape whether the target is a document root or a deeply nested concept. There is no separate "whole file" vs "specific node" indicator at the URL level — the graph's resolver figures out the target's placement and responds accordingly.

The `/uuid/<X>` form is the recommended shape in author-written links to nodes on this graph from other graphs (`https://<other-host>/uuid/<X>`). Within a graph, authors write bare UUID keys; the link builder resolves them and writes the direct `url` beside each one, so a reader inside a built graph reaches the resolver only for UUIDs that arrived from outside it.

### `/search` — general search

A more general search surface. Where `/uuid/<X>` answers exactly one question (where does this UUID resolve?), `/search` answers open-ended graph queries — full-text, by concept relationship, etc.

`uuid` is the one query parameter the spec fixes. `/search?uuid=<X>` performs the UUID lookup described above and responds the same way `/uuid/<X>` does. Every other parameter is per-graph; the spec doesn't fix the rest of the query vocabulary.

Typical use is browsable — a human or agent hits `/search?q=something` and gets a paginated list of matching concepts. Programmatic use is also fine; each graph's server decides its own query surface.

`/search` and `/uuid/<X>` are complementary. `/uuid/<X>` is the fast direct-address path; `/search` is the exploratory path — and `uuid=` is the point where the two overlap.

## Internal consistency

By contract, a graph is internally consistent at the moment it is served. A served graph SHOULD have no dead links: every reference in every node resolves, and every backlink is current.

The point of the contract is that a reader can spider the graph with fetches alone. Every link in a built node carries its resolved `url`, so following an edge is one GET — no resolver call, no search query. `/uuid/<X>` and `/search` are for readers arriving cold with a bare UUID or a question; a reader already inside the graph never needs them.

Meeting that contract means the link builder has been run since the last author edit. Reverse links that were never computed — or were computed before the edit that created them — are stale, and a reader walking one lands nowhere.

## Link builder

A **link builder** walks a graph's nodes and populates the fields derivable from other nodes — reverse-link entries, sitemaps, per-document breadcrumbs, anything else derivable from the graph's structure.

A graph works without a link builder; running one makes reverse-link navigation possible and keeps derived fields in sync with author edits. Each graph runs its own link builder with its own rules; the spec fixes the minimum reverse-link surface but doesn't standardize the full behavior.

A link builder SHOULD be idempotent. A graph's owner MAY run it on every change, on a schedule, or on demand — the spec picks no cadence.

## Deployed forms

A graph may exist as:

- **A live web site.** Deployed at a hostname and served over HTTP. The `/uuid/<X>` resolver, `/search` surface, reverse-link fields, and any interactive features are all live. This is what "site" means — a graph deployed as a web site.
- **A local file tree.** Files on disk. Tools identify the root by the `vibecode.root` marker in its top directory. Cross-graph references still use full URLs; internal references still use UUIDs.

The same graph often exists in both forms simultaneously — the local file tree is the authoring surface; the site is the deployed form. A link builder runs against the local tree, producing the deployed site.
