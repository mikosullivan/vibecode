#!/usr/bin/env lua5.4
--[[
{
	"module": "vibecode.build-links",
	"role": "The link builder. Walks a vibecode graph in one pass, resolves every `meta.links` key to the target's location and brief, writes the reverse direction as `meta.backlinks`, writes `meta.supersedes` from `meta.superseded_by`, and regenerates the graph-root indexes `sitemap.json` and `uuids.txt`. Implements docs/graph/link-builder.md.",
	"strategy": "Parse every document with the order-preserving decoder in ./json.lua, strip the fields the builder owns, recompute them from the whole graph, and re-emit. Builder-owned fields are always stripped and regenerated rather than merged, so copied metadata cannot drift and reruns are byte-identical.",
	"exports": "none — script; run from the graph root: `build-links.lua`"
}
]]

package.path = (arg[0]:match("^(.*)/[^/]*$") or ".") .. "/?.lua;" .. package.path
local J = require("json")

local ROOT_MARKER = "vibecode.root"

--[[ =================================================================
Error collection — every problem in one pass, per the spec.
================================================================= ]]

local errors = {}

local function fail(where, msg)
	errors[#errors + 1] = {where = where, msg = msg}
end

--[[ =================================================================
Filesystem
================================================================= ]]

local function read_file(path)
	local fh = io.open(path, "rb")
	if not fh then return nil end
	local text = fh:read("a")
	fh:close()
	return text
end

local function write_if_changed(path, text)
	if read_file(path) == text then return false end
	local fh = assert(io.open(path, "wb"))
	fh:write(text)
	fh:close()
	return true
end

local function shell_quote(s)
	return "'" .. s:gsub("'", "'\\''") .. "'"
end

-- Follow symlinks: a graph often stitches in content whose canonical home
-- is elsewhere, and a walk that ignores symlinks silently misses part of it.
local function find_documents(root)
	local cmd = "find -L " .. shell_quote(root)
		.. " -name '*.json' -type f -not -path '*/.git/*' -print"
	local pipe = assert(io.popen(cmd, "r"))
	local paths = {}
	for line in pipe:lines() do paths[#paths + 1] = line end
	pipe:close()
	table.sort(paths)
	return paths
end

--[[ =================================================================
Addressing

A document at <path>/index.json is served at <root>/<path>/.
Any other document is served at its own path.
================================================================= ]]

local function url_path(root, file_path)
	local rel = file_path:sub(#root + 1)
	local dir = rel:match("^(.*)/index%.json$")
	if dir then return dir == "" and "/" or (dir .. "/") end
	return rel
end

--[[ =================================================================
Concept discovery

Any hash carrying a string `uuid` is a referenceable concept. Concepts nest,
so the walk descends through every hash in the document.
================================================================= ]]

local function brief_of(node)
	local meta = node.meta
	if J.is_object(meta) and meta.brief ~= nil then return meta.brief end
	return nil
end

local function walk_concepts(node, visit, is_doc_root)
	if not J.is_object(node) then
		if J.is_array(node) then
			for i = 1, #node do walk_concepts(node[i], visit, false) end
		end
		return
	end
	if type(node.uuid) == "string" then visit(node, is_doc_root) end
	for _, k in ipairs(J.keys(node)) do
		walk_concepts(node[k], visit, false)
	end
end

--[[ =================================================================
Builder-owned fields

Always stripped and regenerated. The builder cannot tell an author's stale
`tgt` from one it wrote last run, so it never trusts either.
================================================================= ]]

local function strip_generated(node)
	local meta = node.meta
	if not J.is_object(meta) then return end
	J.remove(meta, "backlinks")
	J.remove(meta, "supersedes")
	local links = meta.links
	if J.is_object(links) then
		for _, key in ipairs(J.keys(links)) do
			local entry = links[key]
			if J.is_object(entry) then J.remove(entry, "tgt") end
		end
	end
end

--[[ =================================================================
Main
================================================================= ]]

local function main()
	-- No arguments. The graph root is the working directory, and everything
	-- else the builder needs comes out of the graph itself.
	if arg[1] then
		io.stderr:write(("unexpected argument %q\n"):format(arg[1]))
		io.stderr:write("usage: build-links.lua — run it from the graph root.\n")
		os.exit(1)
	end

	-- The builder runs in the graph root and nowhere else. No upward search:
	-- if this directory is not a graph root, that is the error.
	local root = "."
	if not read_file(root .. "/" .. ROOT_MARKER) then
		io.stderr:write("not a graph root — no " .. ROOT_MARKER .. " in the working directory\n")
		os.exit(1)
	end

	local sitemap_path = root .. "/sitemap.json"
	local uuids_path = root .. "/uuids.txt"

	-- ---- Load every document -------------------------------------------
	local docs = {}      -- ordered list of {path, url, data}
	for _, path in ipairs(find_documents(root)) do
		if path ~= sitemap_path then
			local text = read_file(path)
			local data, err = J.decode(text)
			if not data then
				fail(path, "malformed JSON — " .. err)
			elseif not J.is_object(data) then
				fail(path, "document is not a JSON object")
			else
				docs[#docs + 1] = {path = path, url = url_path(root, path), data = data}
			end
		end
	end

	-- ---- The graph's own address, from the home document ---------------
	-- Absolute addresses are a property of the graph, not of how the builder
	-- was invoked, so this comes out of a file rather than off the command line.
	local base_url, home_doc
	for _, doc in ipairs(docs) do
		if doc.url == "/" then
			home_doc = doc
			local meta = doc.data.meta
			if J.is_object(meta) and type(meta.base_url) == "string" then
				base_url = meta.base_url:gsub("/+$", "")
			end
			break
		end
	end
	if not home_doc then
		fail(root .. "/index.json", "no home document at the graph root")
	elseif not base_url then
		fail(home_doc.path, "no meta.base_url — the graph does not declare its own address")
	end

	-- ---- Index every concept carrying a uuid ---------------------------
	local index = {}     -- uuid -> {node, url, doc}
	for _, doc in ipairs(docs) do
		walk_concepts(doc.data, function(node, is_doc_root)
			local uuid = node.uuid
			local prior = index[uuid]
			if prior then
				fail(doc.path, ("duplicate uuid %s — also in %s"):format(uuid, prior.doc.path))
				return
			end
			index[uuid] = {
				node = node,
				doc = doc,
				-- A nested concept is addressed by fragment; a document root is not.
				url = is_doc_root and doc.url or (doc.url .. "#" .. uuid),
			}
		end, true)
	end

	-- ---- Strip what the builder owns, before recomputing ---------------
	for _, doc in ipairs(docs) do
		walk_concepts(doc.data, strip_generated, true)
	end

	-- ---- Resolve links, collect the reverse direction ------------------
	local backlinks = {}   -- target uuid -> list of entries
	local supersedes = {}  -- successor uuid -> list of {uuid, value}

	local function canonical(uuid)
		if not base_url then return nil end
		return base_url .. "/uuid/" .. uuid
	end

	for _, doc in ipairs(docs) do
		walk_concepts(doc.data, function(node)
			local meta = node.meta
			if not J.is_object(meta) then return end

			local links = meta.links
			if J.is_object(links) then
				for _, key in ipairs(J.keys(links)) do
					local entry = links[key]
					if not J.is_object(entry) then
						fail(doc.path, ("links entry %q is not a hash"):format(key))
					elseif key:match("^https?://") then
						-- Cross-graph. The builder cannot resolve another graph's
						-- layout, and the key is already that graph's address, so
						-- there is nothing to add.
					else
						local target = index[key]
						if not target then
							fail(doc.path, ("dangling link — no concept has uuid %s"):format(key))
						else
							local tgt = J.object()
							local b = brief_of(target.node)
							if b ~= nil then J.set(tgt, "brief", b) end
							J.set(tgt, "url", target.url)
							local c = canonical(key)
							if c then J.set(tgt, "canonical_url", c) end
							J.set(entry, "tgt", tgt)

							if type(node.uuid) == "string" then
								local bl = J.object()
								J.set(bl, "src", node.uuid)
								if entry.rel ~= nil then J.set(bl, "rel", entry.rel) end
								local sb = brief_of(node)
								if sb ~= nil then J.set(bl, "brief", sb) end
								J.set(bl, "url", index[node.uuid].url)
								local sc = canonical(node.uuid)
								if sc then J.set(bl, "canonical_url", sc) end
								backlinks[key] = backlinks[key] or {}
								table.insert(backlinks[key], {key = node.uuid, value = bl})
							end
						end
					end
				end
			end

			local sby = meta.superseded_by
			if J.is_object(sby) and type(node.uuid) == "string" then
				for _, key in ipairs(J.keys(sby)) do
					if not index[key] and not key:match("^https?://") then
						fail(doc.path, ("dangling superseded_by — no concept has uuid %s"):format(key))
					else
						supersedes[key] = supersedes[key] or {}
						table.insert(supersedes[key], {key = node.uuid, value = sby[key]})
					end
				end
			end
		end, true)
	end

	if #errors > 0 then
		table.sort(errors, function(a, b)
			if a.where ~= b.where then return a.where < b.where end
			return a.msg < b.msg
		end)
		for _, e in ipairs(errors) do
			io.stderr:write(("%s: %s\n"):format(e.where, e.msg))
		end
		io.stderr:write(("\n%d problem(s); nothing written.\n"):format(#errors))
		os.exit(1)
	end

	-- ---- Write the reverse-direction fields ----------------------------
	local function attach(map, field)
		for uuid, entries in pairs(map) do
			local target = index[uuid]
			if target then
				table.sort(entries, function(a, b) return a.key < b.key end)
				local hash = J.object()
				for _, e in ipairs(entries) do J.set(hash, e.key, e.value) end
				local meta = target.node.meta
				if not J.is_object(meta) then
					meta = J.object()
					J.set(target.node, "meta", meta)
				end
				J.set(meta, field, hash)
			end
		end
	end
	attach(backlinks, "backlinks")
	attach(supersedes, "supersedes")

	-- ---- Graph-root indexes --------------------------------------------
	-- The sitemap mirrors the directory tree. A node carries the descriptor for
	-- the document at its position, then `children` for what sits below it, so
	-- a directory that is also a document needs no marker of its own.
	local tree = {children = {}}
	for _, doc in ipairs(docs) do
		local node = tree
		for segment in doc.url:gmatch("[^/]+") do
			node.children[segment] = node.children[segment] or {children = {}}
			node = node.children[segment]
		end
		node.doc = doc
	end

	local function sitemap_node(node)
		local out = J.object()
		if node.doc then
			local meta = node.doc.data.meta
			if J.is_object(meta) and meta.brief ~= nil then J.set(out, "brief", meta.brief) end
			J.set(out, "url", node.doc.url)
			local uuid = node.doc.data.uuid
			if type(uuid) == "string" then
				local c = canonical(uuid)
				if c then J.set(out, "canonical_url", c) end
			end
		end
		local names = {}
		for name in pairs(node.children) do names[#names + 1] = name end
		table.sort(names)
		if #names > 0 then
			local kids = J.object()
			for _, name in ipairs(names) do
				J.set(kids, name, sitemap_node(node.children[name]))
			end
			J.set(out, "children", kids)
		end
		return out
	end
	local sitemap = sitemap_node(tree)

	local uuid_list = {}
	for uuid, rec in pairs(index) do uuid_list[#uuid_list + 1] = uuid end
	table.sort(uuid_list)
	local lines = {}
	for _, uuid in ipairs(uuid_list) do
		local rec = index[uuid]
		local row = uuid .. "\t" .. rec.doc.url
		local b = brief_of(rec.node)
		if b ~= nil then
			local d = J.set(J.object(), "brief", b)
			row = row .. "\t" .. J.encode(d, {indent = false})
		end
		lines[#lines + 1] = row
	end

	-- ---- Write everything ----------------------------------------------
	local changed = 0
	for _, doc in ipairs(docs) do
		if write_if_changed(doc.path, J.encode(doc.data) .. "\n") then changed = changed + 1 end
	end
	if write_if_changed(sitemap_path, J.encode(sitemap) .. "\n") then changed = changed + 1 end
	if write_if_changed(uuids_path, table.concat(lines, "\n") .. (#lines > 0 and "\n" or "")) then
		changed = changed + 1
	end

	io.write(("%d document(s), %d concept(s) with uuids, %d file(s) changed.\n")
		:format(#docs, #uuid_list, changed))
end

main()
