# File structure

~~~vibecode
{"vibecode": {
	"doc": "vibecode-standard-file-structure",
	"role": "Vibecode spec page describing the on-disk layout of a file-based graph — the `vibecode.root` marker and the files a graph root holds. Companion to the graph page, which covers what a graph is and what surfaces a deployed graph exposes over HTTP.",
	"status": "draft — first cut; several requirements still open"
}}
~~~

A file-based graph is a directory tree. This page describes what that tree is required to contain. The [graph page](./) covers what a graph is and what a deployed graph exposes over HTTP.

## The root directory

### `vibecode.root`

The top directory of the tree holds a file named `vibecode.root`. Its contents are irrelevant. The existence of the file indicates that the directory is the
root of the graph.

### `index.json`

The home document — the concept served at the graph's root URL, and the entry point for a reader arriving with nothing but a hostname or a directory path.

It is also where the graph declares its own address, in [`meta.base_url`](./meta/). No other document carries that field.

### `sitemap.json`

A map of every document in the graph, nested the way the directory tree is nested. One request gives a reader the whole inventory — what documents exist, what each is about, and where the hierarchy puts them.

~~~json
{
	"brief": "Root of the Starfleet technical documentation graph.",
	"url": "/",
	"canonical_url": "https://vibecode.caspian.uno/uuid/018f0000-0000-7000-8000-000000000000",
	"children": {
		"starfleet": {
			"children": {
				"ship-classes.json": {
					"brief": "Canonical vocabulary for Federation vessel classes.",
					"url": "/starfleet/ship-classes.json",
					"canonical_url": "https://vibecode.caspian.uno/uuid/018f1111-1111-7000-8000-000000000000"
				}
			}
		}
	}
}
~~~

Every node has the same shape: the fields describing the document at that position, then a `children` hash holding what sits below it. Those fields are the same three a link's [`tgt`](./links.md) carries, so a reader parses the same descriptor here that it parses everywhere else.

- **Keys are path segments.** Joining the keys from the root down to a node reconstructs that node's path, so the hierarchy is readable without parsing URL strings.
- **`children`** holds the nodes below this one. Absent on a leaf.
- **A grouping directory** — one with no document of its own — carries `children` and nothing else. A node without a `url` means there is no document at that position, not a missing field.
- **The root node** is the document at the graph root, carrying the same fields as any other node rather than a special case at the top.

The sitemap is page-level. A concept nested inside a document gets no entry here; [uuids.txt](./uuids.md) is the concept-level index. The two do not overlap — one answers what exists, the other answers where a given handle points.

### `uuids.txt`

A flat list of the concepts in the graph that have UUIDs, giving the file holding each one and a short description of what it is. See [uuids.txt](./uuids.md) for the format.
