# uuids.txt

~~~vibecode
{"vibecode": {
	"doc": "vibecode-standard-uuids-txt",
	"role": "Vibecode spec page describing the `uuids.txt` file at a graph root — a flat, UUID-sorted list of the concepts in the graph that have UUIDs, giving the file holding each one and a short description of what it is. Covers the three tab-separated fields, the escaping and sorting rules, and why the file is plain text.",
	"status": "draft"
}}
~~~

A list of the concepts in the graph that have UUIDs, with the file holding each one and a short description of what it is. One record per line, three tab-separated fields:

~~~txt
018f1234-5678-7abc-def0-123456789abc	/starfleet/ship-classes.json	{"brief": "Canonical vocabulary for Federation vessel classes."}
018f5555-6666-7abc-def0-777788889999	/foo/bar/index.json
018fabcd-1234-7000-9abc-fedcba987654	/starfleet/phaser-calibration.json	{"brief": "How the Enterprise-D's main phaser array is calibrated."}
~~~

- **UUID.** The node's identifier.
- **Path.** The file holding the node, as a path from the graph root. The file, not a position inside it — the same path whether the UUID names the document itself or a concept nested within it.
- **Description.** A hash describing the node. It currently carries one field, `brief`, copied from the node's `meta.brief`. Optional; a line for a node without one ends after the path.

A reader needing an anchor into the file builds it from the first two columns — `<path>#<uuid>`. The path carries no fragment of its own, which would only repeat the UUID already sitting in column one.

A line does not say whether its UUID names the document or a concept nested inside it, and a reader does not need to know. Either way it fetches the file and matches the UUID against the nodes in it.

A concept with no UUID has no line here. The file is an index of what can be referenced, not an inventory of everything the graph contains.

Fields are separated by a single tab. The UUID and the path MUST NOT contain a tab or a newline.

The description is a JSON value serialized onto a single line. Tabs and newlines inside it MUST be written as the JSON escapes `\t` and `\n`, never as literal characters, and the value MUST NOT be pretty-printed across multiple lines. Whatever it holds, it cannot break the one-record-per-line rule.

Lines MUST be sorted by UUID in ascending order.