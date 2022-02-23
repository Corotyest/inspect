--[[lit-meta
	name = 'Corotyest/inspect'
	version = '0.3.0'
]]

local format, rep, sort = string.format, string.rep, table.sort

-- local colors = {--[[lit-meta
	name = 'Corotyest/inspect'
	version = '1.0.1-beta'
]]

local getuserdata = debug.getuservalue
local sfind, format, rep = string.find, string.format, string.rep
local concat, sort = table.concat, table.sort

local colors = {
	['nil'] = '1;30',
	['string'] = '1;34',
	['thread'] = '1;35',
	['number'] = '1;33',
	['boolean'] = '1;36',
	['function'] = '1;31',
	['userdata'] = '0?'
}

local function isMethod(value)
	return type(value) == 'string' and sfind(value, '__', 1, true) == 1 or nil
end

local function getn(list)
	local num = 0
	for _ in pairs(list) do
		num = num + 1
	end
	return num
end

local function quote(str)
	local quote = sfind(str, '\'', 1, true)
	if quote then
		return format('"%s"', str), '\''
	elseif sfind(str, '"', 1, true) then
		return format('\'%s\'', str), '"'
	else
		return format('\'%s\'', str)
	end
end

local function join(sep, ...)
	if not ... then return nil end

	local base = {...}
	local response = { }
	for _, value in pairs(base) do
		response[#response + 1] = type(value) == 'string' and value or nil
	end

	return quote(concat(response, sep or ' ')), nil
end

local function setcolor(value, special)
	special = special or type(value)
	return '\27[' .. (colors[special] or '0') .. 'm' .. value .. '\27[0m'
end

local function _format(self, value, options)
	local type1 = type(value)
	local usecolor = options and options.usecolor and options.usecolor == true

	if type1 == 'table' then
		local _, v = self.encode(value)
		return _ or v == 'last' and (options and options.recycle_udata and 'userdata: self' or 'table: self')
	elseif type1 == 'userdata' then
		if options then options.recycle_udata = true end

		local _, v = self.encode(getuserdata(value), options or {recycle_udata = true})
		return _ or v == 'last' and 'userdata: self'
	elseif type1 == 'number' then
		return usecolor and setcolor(value, type1) or value
	elseif type1 == 'string' then
		value = join(nil, tostring(value))
		return usecolor and setcolor(value, type1) or value
	elseif type1 == 'boolean' or type1 == 'nil' then
		return usecolor and setcolor(tostring(value), type1) or tostring(value)
	else
		value = join(nil, tostring(value))
		return usecolor and setcolor(value, type1) or value
	end
end

local function field(self, index, value, options)
	local type1, type3 = type(index), type(options)
	if type1 ~= 'string' then
		if type1 ~= 'number' then return nil end
	elseif options and type3 ~= 'table' then
		return nil
	end

	local tabs = options and options.tabs ~= false and rep('\t', options and options.tabs or 1)

	local isplat = type1 == 'number' and index > 0
	local plat = isplat and self.plat0 or type1 == 'string' and self.plat1 or self.plat1

	plat = format(plat, tabs or '', '%s', '%s')
	
	return isplat and format(plat, _format(self, value, options)) or format(plat, _format(self, index, options), _format(self, value, options))
end

local seen = { }

local function sortFn(_in, out)
	local value, value1 = _in[2], out[2]
	if type(value) == 'table' and not seen[value] then
		sort(value, sortFn); seen[value] = true
	end
	if type(value1) == 'table' and not seen[value1] then
		sort(value1, sortFn); seen[value] = true
	end
	seen[value] = seen[value] and nil; seen[value1] = seen[value1] and nil

	local index, index1 = _in[1], out[1]
	local i, i1 = type(index), type(index1)

	if i == 'number' then
		return index and i1 == 'number' and index < index1 or i1 ~= 'number' and index > #index1
	else
		return i1 ~= 'number' and #index < #index1
	end
end

local function order(table, fn)
	local type1 = type(table)
	if type1 ~= 'table' then
		return nil
	elseif fn and type(fn) ~= 'function' then
		return nil, 'argument #2 for order is not a function'
	end

	local response = { }

	for index, value in pairs(table) do
		response[#response + 1] = { index, value }
	end

	sort(response, fn or sortFn)
	return next, response
end

-- pourpose only for pass `self`
local inspect = {
	getn = getn,
	join = join,
	order = order,
	plat0 = '%s%s',
	plat1 = '%s[%s] = %s',
	field = field,
	quote = quote,
	format = format,
	usecolors = true
}

local last

function inspect.encode(value, options)
	local type1, type2 = type(value), type(options)
	if type1 ~= 'table' then
		return _format(inspect, value, options)
	elseif options and type2 ~= 'table' then
		return nil, 'argument #2 must be table'
	end

	if last == value then return nil, 'last' end

	last = value

	options = options or {} -- skip errors

	local content = getn(value)
	if content == 0 then return setcolor('{}', 'nil') end

	local methods = { }
	local response = { }

	for _, data in order(value, options.sortFn) do
		local key, value = data[1], data[2]
		local field = field(inspect, key, value, options)

		if isMethod(key) then
			methods[#methods + 1] = field
		else
			response[#response + 1] = field
		end
	end

	return format('{\n%s}', format('%s%s%s',
		#methods ~= 0 and concat(methods, ',\n') .. '\n\n' or '',
		concat(response, ',\n'),
		#response > 0 and '\n' or ''
	))
end

local console = io.stdout

--- Writes directly to stdout, but in a beatiful format [, set inspect `usecolors` nil to write without colors].
---@vararg any
function inspect.show(...)
	for index = 1, select('#', ...) do
		console:write(inspect.encode(select(index, ...), { usecolor = inspect.usecolors }))
		console:write'    '
	end
	console:write('\n')
end

--- Writes directly to stdout
---@vararg any
function inspect.print(...)
	for index = 1, select('#', ...) do
		local value = select(index, ...)
		console:write(tostring(value))
	end
end

return inspect
-- 	['nil'] = '1;30',
-- 	['sep'] = '1;30',
-- 	['table'] = '1;34',
-- 	['field'] = '0;37',
-- 	['string'] = '0;32',
-- 	['braces'] = '1;30',
-- 	['thread'] = '1;35',
-- 	['number'] = '1;33',
-- 	['quotes'] = '1;32',
-- 	['boolean'] = '0;33',
-- 	['function'] = '0;35',
-- 	['userdata'] = '1;36',
-- } not yet

local function getn(list)
	local num = 0
	for _ in pairs(list) do
		num = num + 1
	end
	return num
end

local last, getuserdata = nil, debug.getuservalue

local function isMethod(string)
	return type(string) == 'string' and string:find('__', 1, true) == 1
end

local last1, last2

local function sortfn(a, b)
	if type(a[2]) == 'table' and not a[2] == last1 then sort(a[2], sortfn); last1 = a[2] end
	if type(b[2]) == 'table' and not b[2] == last2 then sort(b[2], sortfn); last2 = b[2] end

	if #a[1] < #b[1] then
		return true
	end
end

local function order(list, fn)
	local clone = {}
	for index, value in pairs(list) do
		clone[#clone + 1] = { index, value }
	end
	
	sort(clone, fn or sortfn)

	return next, clone
end

local function makeField(self, _index, _value, tabs)
	local type1 = type(_value)
	local tag = type1 == 'userdata' and tostring(_value)
	return format('%s[\'%s\'] = %s,\n',
		rep('\t', tabs),
		tostring(_index),
		type1 ~= 'table' and format(type1 == 'string' and '\'%s\'' or '%s', tostring(_value)) or
			last == _value and 'table: self' or self:encode(_value, tabs + 1, tag)
	)
end

local function encode(self, list, tabs, tag)
	if last and last == list then
		return tostring(list)
	end

	last = list

	local type1 = type(list)
	if type1 ~= 'table' then
		if type1 == 'userdata' then return self:encode(getuserdata(list), tabs, tostring(list)) end
		return tostring(list)
	end

	local n = getn(list)

	local response, methods = '', ''
	tabs = tabs or 1

	for _, data in order(list) do
		local _index, _value = data[1], data[2]
		if isMethod(_index) then
			methods = methods .. self:makeField(_index, _value, tabs)
		else
			response = response .. self:makeField(_index, _value, tabs)
		end
	end

	tag = tag and format('userdata %s: ', tag:gsub('^%a*(%s+)', ''))

	return format('%s{%s%s%s}',
		tag or '',
		n~=0 and '\n' or '',
		#methods~=0 and methods .. '\n' or '',
		response,
		n~=0 and rep('\t', tabs - 1) or '')
end

return setmetatable({
	getn = getn,
	colors = colors,
	encode = encode,
	isMethod = isMethod,
	makeField = makeField
}, {__call = encode})
