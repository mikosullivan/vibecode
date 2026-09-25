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

### `sitemap.json`

An index of every document in the graph, one entry per document. Each entry carries the document's URL and its orientation fields, so a reader can decide what is worth fetching without fetching any of it:

~~~json
{
	"/starfleet/ship-classes.json": {
		"title": "Starfleet ship classes",
		"brief": "Canonical vocabulary for Federation vessel classes.",
		"audience": "AI agents generating content about Starfleet ships"
	}
}
~~~

One request gives a reader the full inventory of the graph. An agent that has fetched the sitemap can filter and rank locally instead of asking the graph to search on its behalf.

### `uuids.txt`

A flat list of the concepts in the graph that have UUIDs, giving the file holding each one and a short description of what it is. See [uuids.txt](./uuids.md) for the format.
