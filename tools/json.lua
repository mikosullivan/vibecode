--[[
{
	"module": "vibecode.json",
	"role": "Order-preserving JSON decode/encode for the link builder. Lua tables have no key order, so a decoded object records its key order in its metatable and the encoder emits keys in that order. This is what lets the builder rewrite a document without disturbing the author's field order, and what makes byte-identical reruns possible.",
	"note": "dkjson was not used because it discards key order on decode. Nothing here depends on luarocks.",
	"exports": "decode(text) -> value, err; encode(value, opts) -> string; NULL sentinel; object(); is_object(v); keys(obj); set(obj, k, v); remove(obj, k)"
}
]]

local M = {}

-- JSON null. Lua cannot store nil in a table, so null decodes to this.
M.NULL = setmetatable({}, {__tostring = function() return "null" end})

--[[ =================================================================
Ordered objects

An object is a plain Lua table carrying its key order in the metatable.
`obj.foo` works normally; iteration goes through M.keys(obj).
================================================================= ]]

local function new_object()
	return setmetatable({}, {__jsontype = "object", __keyorder = {}})
end
M.object = new_object

function M.is_object(v)
	if type(v) ~= "table" then return false end
	local mt = getmetatable(v)
	return mt ~= nil and mt.__jsontype == "object"
end

function M.is_array(v)
	if type(v) ~= "table" then return false end
	local mt = getmetatable(v)
	return mt ~= nil and mt.__jsontype == "array"
end

function M.array(t)
	return setmetatable(t or {}, {__jsontype = "array"})
end

-- Key order of an object, as a fresh list.
function M.keys(obj)
	local order = getmetatable(obj).__keyorder
	local out = {}
	for i = 1, #order do out[i] = order[i] end
	return out
end

-- Set a key, appending to the order if it is new. Existing keys keep position.
function M.set(obj, k, v)
	local mt = getmetatable(obj)
	if obj[k] == nil then table.insert(mt.__keyorder, k) end
	obj[k] = v
	return obj
end

function M.remove(obj, k)
	if obj[k] == nil then return obj end
	obj[k] = nil
	local order = getmetatable(obj).__keyorder
	for i = 1, #order do
		if order[i] == k then table.remove(order, i) break end
	end
	return obj
end

-- Move `k` to the front of the key order. Used to keep `uuid` and `meta`
-- leading a hash regardless of where an author put them.
function M.move_to_front(obj, k)
	if obj[k] == nil then return obj end
	local order = getmetatable(obj).__keyorder
	for i = 1, #order do
		if order[i] == k then table.remove(order, i) break end
	end
	table.insert(order, 1, k)
	return obj
end

--[[ =================================================================
Decode
================================================================= ]]

local ESCAPES = {
	['"'] = '"', ['\\'] = '\\', ['/'] = '/',
	b = '\b', f = '\f', n = '\n', r = '\r', t = '\t',
}

local function utf8_encode(cp)
	if cp < 0x80 then return string.char(cp) end
	if cp < 0x800 then
		return string.char(0xC0 | (cp >> 6), 0x80 | (cp & 0x3F))
	end
	if cp < 0x10000 then
		return string.char(0xE0 | (cp >> 12), 0x80 | ((cp >> 6) & 0x3F), 0x80 | (cp & 0x3F))
	end
	return string.char(0xF0 | (cp >> 18), 0x80 | ((cp >> 12) & 0x3F),
		0x80 | ((cp >> 6) & 0x3F), 0x80 | (cp & 0x3F))
end

local Parser = {}
Parser.__index = Parser

function Parser.new(text)
	return setmetatable({s = text, i = 1, n = #text}, Parser)
end

function Parser:err(msg)
	-- Report a line number; a byte offset is useless to a person.
	local line = 1
	for _ in self.s:sub(1, self.i):gmatch("\n") do line = line + 1 end
	error({line = line, msg = msg}, 0)
end

function Parser:skip_ws()
	local _, j = self.s:find("^[ \t\r\n]*", self.i)
	self.i = j + 1
end

function Parser:peek()
	return self.s:sub(self.i, self.i)
end

function Parser:expect(c)
	if self:peek() ~= c then self:err("expected '" .. c .. "'") end
	self.i = self.i + 1
end

function Parser:parse_string()
	self:expect('"')
	local buf, start = {}, self.i
	while true do
		if self.i > self.n then self:err("unterminated string") end
		local c = self.s:sub(self.i, self.i)
		if c == '"' then
			buf[#buf + 1] = self.s:sub(start, self.i - 1)
			self.i = self.i + 1
			return table.concat(buf)
		elseif c == "\\" then
			buf[#buf + 1] = self.s:sub(start, self.i - 1)
			local e = self.s:sub(self.i + 1, self.i + 1)
			if ESCAPES[e] then
				buf[#buf + 1] = ESCAPES[e]
				self.i = self.i + 2
			elseif e == "u" then
				local hex = self.s:sub(self.i + 2, self.i + 5)
				if not hex:match("^%x%x%x%x$") then self:err("bad \\u escape") end
				local cp = tonumber(hex, 16)
				self.i = self.i + 6
				-- Surrogate pair.
				if cp >= 0xD800 and cp <= 0xDBFF and self.s:sub(self.i, self.i + 1) == "\\u" then
					local lo = tonumber(self.s:sub(self.i + 2, self.i + 5), 16)
					if lo and lo >= 0xDC00 and lo <= 0xDFFF then
						cp = 0x10000 + ((cp - 0xD800) << 10) + (lo - 0xDC00)
						self.i = self.i + 6
					end
				end
				buf[#buf + 1] = utf8_encode(cp)
			else
				self:err("bad escape '\\" .. e .. "'")
			end
			start = self.i
		else
			self.i = self.i + 1
		end
	end
end

function Parser:parse_number()
	local num = self.s:match("^-?%d+%.?%d*[eE]?[-+]?%d*", self.i)
	if not num or num == "" then self:err("bad number") end
	local v = tonumber(num)
	if not v then self:err("bad number '" .. num .. "'") end
	self.i = self.i + #num
	return v
end

function Parser:parse_value()
	self:skip_ws()
	local c = self:peek()
	if c == "" then self:err("unexpected end of input") end
	if c == "{" then return self:parse_object() end
	if c == "[" then return self:parse_array() end
	if c == '"' then return self:parse_string() end
	if c == "t" then
		if self.s:sub(self.i, self.i + 3) ~= "true" then self:err("bad literal") end
		self.i = self.i + 4 return true
	end
	if c == "f" then
		if self.s:sub(self.i, self.i + 4) ~= "false" then self:err("bad literal") end
		self.i = self.i + 5 return false
	end
	if c == "n" then
		if self.s:sub(self.i, self.i + 3) ~= "null" then self:err("bad literal") end
		self.i = self.i + 4 return M.NULL
	end
	return self:parse_number()
end

function Parser:parse_object()
	self:expect("{")
	local obj = new_object()
	self:skip_ws()
	if self:peek() == "}" then self.i = self.i + 1 return obj end
	while true do
		self:skip_ws()
		local k = self:parse_string()
		self:skip_ws()
		self:expect(":")
		local v = self:parse_value()
		if obj[k] ~= nil then self:err("duplicate key '" .. k .. "'") end
		M.set(obj, k, v)
		self:skip_ws()
		local c = self:peek()
		if c == "," then self.i = self.i + 1
		elseif c == "}" then self.i = self.i + 1 return obj
		else self:err("expected ',' or '}'") end
	end
end

function Parser:parse_array()
	self:expect("[")
	local arr = M.array({})
	self:skip_ws()
	if self:peek() == "]" then self.i = self.i + 1 return arr end
	while true do
		arr[#arr + 1] = self:parse_value()
		self:skip_ws()
		local c = self:peek()
		if c == "," then self.i = self.i + 1
		elseif c == "]" then self.i = self.i + 1 return arr
		else self:err("expected ',' or ']'") end
	end
end

-- decode(text) -> value, nil  |  nil, "line N: message"
function M.decode(text)
	local p = Parser.new(text)
	local ok, result = pcall(function()
		local v = p:parse_value()
		p:skip_ws()
		if p.i <= p.n then p:err("trailing content") end
		return v
	end)
	if ok then return result end
	if type(result) == "table" then
		return nil, ("line %d: %s"):format(result.line, result.msg)
	end
	return nil, tostring(result)
end

--[[ =================================================================
Encode
================================================================= ]]

local ESCAPE_OUT = {
	['"'] = '\\"', ['\\'] = '\\\\',
	['\b'] = '\\b', ['\f'] = '\\f', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t',
}

local function escape_string(s)
	return (s:gsub('[%z\1-\31"\\]', function(c)
		return ESCAPE_OUT[c] or ("\\u%04x"):format(c:byte())
	end))
end

local function encode_number(v)
	if v ~= v or v == math.huge or v == -math.huge then
		error("cannot encode non-finite number")
	end
	if math.type(v) == "integer" then return tostring(v) end
	-- %.14g round-trips through Lua's reader without exponent noise.
	local s = ("%.14g"):format(v)
	return s
end

local encode_value

-- indent == nil means compact (no newlines) — used for uuids.txt lines.
local function encode_object(obj, indent, depth)
	local order = M.keys(obj)
	if #order == 0 then return "{}" end
	local pad, inner, nl, sep
	if indent then
		pad = indent:rep(depth)
		inner = indent:rep(depth + 1)
		nl = "\n"
		sep = ",\n"
	else
		pad, inner, nl, sep = "", "", "", ", "
	end
	local parts = {}
	for i = 1, #order do
		local k = order[i]
		parts[i] = inner .. '"' .. escape_string(k) .. '": ' .. encode_value(obj[k], indent, depth + 1)
	end
	return "{" .. nl .. table.concat(parts, sep) .. nl .. pad .. "}"
end

local function encode_array(arr, indent, depth)
	if #arr == 0 then return "[]" end
	local pad, inner, nl, sep
	if indent then
		pad = indent:rep(depth)
		inner = indent:rep(depth + 1)
		nl = "\n"
		sep = ",\n"
	else
		pad, inner, nl, sep = "", "", "", ", "
	end
	local parts = {}
	for i = 1, #arr do
		parts[i] = inner .. encode_value(arr[i], indent, depth + 1)
	end
	return "[" .. nl .. table.concat(parts, sep) .. nl .. pad .. "]"
end

encode_value = function(v, indent, depth)
	if v == M.NULL then return "null" end
	local t = type(v)
	if t == "string" then return '"' .. escape_string(v) .. '"' end
	if t == "number" then return encode_number(v) end
	if t == "boolean" then return tostring(v) end
	if t == "table" then
		if M.is_object(v) then return encode_object(v, indent, depth) end
		if M.is_array(v) then return encode_array(v, indent, depth) end
		-- Untagged table: array if it has a positive length, else object.
		if #v > 0 then return encode_array(v, indent, depth) end
		return encode_object(setmetatable(v, {__jsontype = "object", __keyorder = {}}), indent, depth)
	end
	error("cannot encode value of type " .. t)
end

-- encode(value, {indent = "\t" | false})
-- Default is tab-indented, matching the house style for vibecode documents.
function M.encode(value, opts)
	opts = opts or {}
	local indent = opts.indent
	if indent == nil then indent = "\t" end
	if indent == false then indent = nil end
	return encode_value(value, indent, 0)
end

return M
