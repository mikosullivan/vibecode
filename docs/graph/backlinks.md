# Backlinks

~~~vibecode
{"vibecode": {
	"doc": "vibecode-standard-backlinks",
	"role": "Vibecode spec page describing backlinks — the reverse-direction entries the link builder writes on a node for every link pointing at it. Agents read backlinks; they never build them. A backlink names its source with `src` and otherwise has the same structure as a link's `tgt`, pointed the other way.",
	"status": "draft"
}}
~~~

A **backlink** is the reverse of a link. For every link one node writes to another, the link builder puts an entry on the target recording who pointed at it. A reader on a node sees who considers it relevant without walking the graph to find out.

Backlinks are written by the link builder. Agents do not build them. An agent that writes a link does nothing further — the reverse entry appears on the next build. Reading is the whole of an agent's involvement with backlinks: they are already in place when the agent arrives on a node.

~~~json
{
	"backlinks": {
		"018f1111-2222-7abc-def0-333344445555": {
			"src": "018f1111-2222-7abc-def0-333344445555",
			"rel": "the procedure invokes this function to compute the ship's approach vector",
			"brief": "Procedure for bringing the ship alongside a starbase docking ring.",
			"url": "/starfleet/docking-procedure.json#018f1111-2222-7abc-def0-333344445555",
			"canonical_url": "https://vibecode.caspian.uno/uuid/018f1111-2222-7abc-def0-333344445555"
		}
	}
}
~~~

## Fields

Every field in a backlink comes from the source node or from the builder's knowledge of where that node sits. The node carrying the backlink contributes nothing to it — which is why an agent never writes one, and why a backlink is only as current as the last build.

| Field | What it holds | Where it comes from |
|---|---|---|
| `src` | The source node's identifier — its UUID on this graph, its resolver URL on another. | The identity of the node whose `links` produced this entry. |
| `rel` | The source's characterization of the relationship. | Copied verbatim from `rel` in the originating link hash, which the source's author wrote. |
| `brief` | A one-line description of the source node. | Copied from the source node's `meta.brief`. Absent when the source has no `brief`. |
| `url` | Direct root-relative path to the source node. | Resolved by the link builder from where the source sits in the graph. Same-graph sources only. |
| `canonical_url` | The source node's permanent address. | Composed by the link builder from the graph's hostname and the source's UUID. Same-graph sources only. |

Nothing in the table is authored in place. `rel` and `brief` are copies of text the source's author wrote; `src`, `url`, and `canonical_url` are addresses the builder worked out. A backlink is therefore always reconstructible from the graph — losing them costs a build, not information.

