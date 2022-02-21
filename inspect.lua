--[[lit-meta
	name = 'Corotyest/inspect'
	version = '0.3.0'
]]

local format, rep, sort = string.format, string.rep, table.sort

-- local colors = {
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