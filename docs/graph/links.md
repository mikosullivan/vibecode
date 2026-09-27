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

A link hash SHOULD have a `rel` field saying **how this node relates** to the one it links to.

`rel` is about the relationship, not about the other node. "The vibecode site" names a destination; "the graph this document is published in" says what the connection is. Only the second is a `rel` — the first is a label, and a reader can already get the other node's name and description from its `tgt`.

There is a test for this. A `rel` is copied verbatim into the [backlink](./backlinks.md) on the other node, where the arrow points the other way. A relationship still reads correctly there. A label turns into a description of whichever node the reader happens to be standing on, which is the node they least need described.

~~~json
{
	"links": {
		"018f1234-5678-7abc-def0-123456789abc": {
			"rel": "prerequisite — this document assumes familiarity with it"
		},
		"018fabcd-1234-7000-9abc-fedcba987654": {
			"rel": "the execution model whose runtime state this schema stores"
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

`rel` is written for an AI audience, so it may take any format. A short name, a sentence, or a hash are all valid. There is no fixed vocabulary, and a consumer should read the value rather than match it against a known set.

## Empty link hash

A link hash may be empty. The reference then says only that the target is related, and nothing more about it:

~~~json
{
	"links": {
		"018f1234-5678-7abc-def0-123456789abc": {}
	}
}
~~~
