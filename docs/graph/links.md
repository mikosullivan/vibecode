# Links

~~~vibecode
{"vibecode": {
	"doc": "vibecode-standard-links",
	"role": "Vibecode spec page describing the format of a link hash — the value that describes a single reference from one concept to another, such as would be used in a `links` element. The author writes `rel`; `tgt` is reserved for the link builder; other fields are allowed but rarely warranted. Not about backlinks.",
	"status": "stub"
}}
~~~

This doc describes the format of a link hash — the value that describes a single reference from one concept to another, such as would be used in a `links` element.

This doc is specifically not about backlinks.

The author writes `rel`. `tgt` is reserved for the link builder — an author-supplied `tgt` is replaced on the next build.

Other fields are allowed and rarely warranted. If you are reaching for one, the meaning probably belongs in `rel`, which takes any format precisely so it can hold it.

## `rel`

A link hash SHOULD have a `rel` field describing the relationship between the current node and the referenced node.

`rel` is written for an AI audience, so it may take any format. A short name, a sentence, or a hash are all valid. There is no fixed vocabulary, and a consumer should read the value rather than match it against a known set.

~~~json
{
	"links": {
		"018f1234-5678-7abc-def0-123456789abc": {
			"rel": "reference"
		},
		"018fabcd-1234-7000-9abc-fedcba987654": {
			"rel": "the procedure invokes this function to compute the ship's approach vector"
		},
		"018f2222-3333-7abc-def0-444455556666": {
			"rel": {
				"kind": "supersedes",
				"note": "same scope, updated tolerances for the Galaxy-class refit"
			}
		}
	}
}
~~~

## `tgt`

Written by the link builder. `tgt` holds what a reader needs in order to decide whether to follow the link without fetching the target first — the target's brief, and where it lives.

~~~json
{
	"links": {
		"018fabcd-1234-7000-9abc-fedcba987654": {
			"rel": "the procedure invokes this function to compute the ship's approach vector",
			"tgt": {
				"brief": "Computes an approach vector from current heading and target orbit.",
				"url": "/starfleet/approach-vector.json#018fabcd-1234-7000-9abc-fedcba987654",
				"canonical_url": "https://vibecode.caspian.uno/uuid/018fabcd-1234-7000-9abc-fedcba987654"
			}
		}
	}
}
~~~

`tgt` has the same structure as a backlink entry — see [backlinks](./backlinks.md). A link and a backlink are one relationship seen from its two ends: `tgt` describes the node being referenced, a backlink entry describes the node doing the referencing.

`tgt` carries a shallow subset of the target's `meta`. It never carries the target's own `links`, which would pull in their targets, and theirs, without terminating.

## Empty link hash

A link hash may be empty. The reference then says only that the target is related, and nothing more about it:

~~~json
{
	"links": {
		"018f1234-5678-7abc-def0-123456789abc": {}
	}
}
~~~
