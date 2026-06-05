--[[ 

	Stream — Reactive State Library


	--- Core API


	Stream.Value(value):
	  Creates a StreamValue, which holds a value and notifies listeners whenever it changes.
	  This type of stream does not have any dependencies.

	   - Example:

	     local counter = Stream.Value(0)
	     counter:set(10)
	     print(counter:get()) -- 10


	Stream.Computed(callback):
	  Creates a StreamComputedValue. Its value is computed based on other stream objects and will be
	  re-computed each time its dependencies (values read via :get() in the callback) change.

	   - Example:

	     local counter = Stream.Value(10)
	     local doubleCounter = Stream.Computed(function()
	       return counter:get() * 2
	     end)
	     print(doubleCounter:get()) -- 20
	     counter:set(20)
	     -- doubleCounter will recompute to 40


	Stream.Listen(target, args):
	  Creates a new listener.
	  If the target is a StreamValue or StreamComputedValue, changes trigger the passed callback.
	  If the target is a normal table or Instance, it creates a bind listener (see Stream.Bind).

	   - Example (stream listener):

	     local counter = Stream.Value(0)
	     local disconnect = Stream.Listen(counter, function(oldValue, newValue)
	       print(oldValue, newValue)
	     end)
	     counter:set(10) -- Prints "0 10"

	   - Example (instance bind listener):

	     local disconnect = Stream.Listen(workspace){
	       Changed_AirDensity = function(oldValue, newValue) end,
	       Attribute_SomeAttributeName = function(oldValue, newValue) end,
	     }


	Stream.Observe(target, callback):
	  Runs the callback immediately with the target's current value, then re-runs it whenever
	  the value changes. The callback may return a cleanup function, which is called before the
	  next re-run and when disconnected.

	   - Example:

	     local state = Stream.Value("Idle")
	     local disconnect = Stream.Observe(state, function(newVal)
	       print("New value ", newVal)
	       return function()
	         print("No longer ", newVal)
	       end
	     end)
	     -- Prints "New value Idle"
	     state:set("Test") -- Prints "No longer Idle", then "New value Test"


	Stream.Bind(target):
	  Allows binding properties of an Instance or table to stream values. When a bound stream
	  changes, the target's property is automatically updated. For Instance targets, supports
	  Event_, Attribute_, and Changed_ prefixed keys for connecting to events, attribute changes,
	  and property changes respectively.

	   - Example (table binding):

	     local myTable = { score = 0 }
	     local counter = Stream.Value(10)
	     local disconnect = Stream.Bind(myTable){
	       score = counter
	     }
	     counter:set(20)
	     print(myTable.score) -- 20

	   - Example (instance binding):

	     local disconnect = Stream.Bind(myPart){
	       Transparency = Stream.Value(0.5),
	       [Stream.Changed.Color] = function(old, new) end,
	       [Stream.Attribute.Health] = function(old, new) end,
	       [Stream.Event.Touched] = function(hit) end,
	     }


	Stream.New(instance, ...):
	  Creates a new instance of a given object type and returns it along with a cleanup function.
	  The first argument can be a Roblox instance class name string or a constructor function.

	   - Example:

	     local label, cleanup = Stream.New("TextLabel", parentInstance)({
	       Text = Stream.Value("Hello, World!")
	     })


	--- Helpers


	Stream.Event[name]:     Produces the key "Event_<name>"     for use in Bind/Listen property tables.
	Stream.Attribute[name]: Produces the key "Attribute_<name>" for use in Bind/Listen property tables.
	Stream.Changed[name]:   Produces the key "Changed_<name>"   for use in Bind/Listen property tables.

	   - Example:

	     Stream.Bind(myPart){
	       [Stream.Event.Touched] = function(hit) end,
	       [Stream.Attribute.Health] = function(old, new) end,
	       [Stream.Changed.Transparency] = function(old, new) end,
	     }


	--- Instance Methods


	StreamValue:get():      Returns the current value. Registers as a dependency if called inside a Computed.
	StreamValue:set(value): Sets the value. Listeners are notified on the next deferred batch.
	StreamValue:Destroy():  Cleans up all listeners, removes from pending changes, and severs dependency links.

	StreamComputedValue:get():     Returns the current computed value. Registers as a dependency if called
	                               inside another Computed.
	StreamComputedValue:Destroy(): Unsubscribes from all dependencies, cleans up listeners, and severs
	                               dependency links.


	--- Utility


	Stream.BindToInstanceProperty(stateObject, instance, prop):
	  Binds a Roblox instance's property to a StreamValue so that whenever the property changes
	  on the instance, the stream is updated via :set(). Returns a disconnect function.

	   - Example:

	     local transparency = Stream.Value(part.Transparency)
	     local disconnect = Stream.BindToInstanceProperty(transparency, part, "Transparency")


	Stream.FromProperty(instance, prop):
	  Creates a StreamValue initialized to the current value of a Roblox instance property and
	  binds to its property changed signal. Returns the StreamValue and a disconnect function.

	   - Example:

	     local transparency, disconnect = Stream.FromProperty(part, "Transparency")


	Stream.FromValueBase(valueBase):
	  Creates a StreamValue from a Roblox ValueBase (IntValue, StringValue, etc.) and binds its
	  .Value property. Returns the StreamValue and a disconnect function.

	   - Example:

	     local stream, disconnect = Stream.FromValueBase(workspace.MyIntValue)


	Stream.FromAttribute(instance, attributeName, callback?):
 	  Creates a StreamValue from a Roblox instance attribute.
  	   Optional callback is fired on changes and once immediately with (nil, currentValue).
 	   Returns the StreamValue and a disconnect function.

	--- Debug API


	Stream.EnableDebug(Iris):
	  Enables the debug , change logging, dependency tracking, and source-line capture
	  
	  !! Call this IMMEDIATELY after requiring Stream for the first time, before any objects are created !!
	 
	 
	  - When disabled (the default), there is no debug overhead


	--- Scope API


	Stream.Scope(category?, displayName?):
	  Creates a new scope for managing the lifetime of stream objects. When destroyed, all items
	  added to the scope are cleaned up in reverse order. Supports optional category and
	  displayName for the debugger.

	   - Example:

	     local scope = Stream.Scope("UI", "HealthBar")
	     local hp = scope:Value(100)
	     local label = scope:Computed(function()
	       return hp:get() .. " HP"
	     end)
	     scope:Destroy() -- Cleans up label first, then hp



	StreamScope:Add(item):               Adds any cleanable item (function, connection, Instance,
	                                     table with Destroy/Disconnect, or thread) to the scope.
	                                     Returns the item.
	                                     
	StreamScope:InnerScope(cat?, name?):  Creates a child scope owned by this scope. Destroyed
	                                     automatically when the parent is destroyed.
	                                     
	                                     
	StreamScope:Value(value):             Shorthand for scope:Add(Stream.Value(value)).
	
	
	StreamScope:Computed(callback):       Shorthand for scope:Add(Stream.Computed(callback)).
	
	StreamScope:Bind(target):             Returns a function(propertiesTable) whose cleanup is
	                                     added to the scope.
	                                     
	StreamScope:Observe(target, cb):      Shorthand for scope:Add(Stream.Observe(target, cb)).
	

	StreamScope:Listen(target, args):     If args is provided, shorthand for
	                                     scope:Add(Stream.Listen(target, args)). If args is nil,
	                                     returns a function(propertiesTable) whose cleanup is
	                                     added to the scope.
	                                     
	                  
	StreamScope:FromProperty(inst, prop): Creates and owns a StreamValue bound to an instance
	                                     property. Returns the StreamValue.
	                                     
	StreamScope:FromValueBase(vb):        Creates and owns a StreamValue bound to a ValueBase.
	                                     Returns the StreamValue.
	                                     
	StreamScope:FromAttribute(inst, attr, cb?):
	                                     Creates and owns a StreamValue bound to an instance
	                                     attribute. Optional callback fires on changes and once
	                                     immediately. Returns the StreamValue.
	                                     

	StreamScope:Destroy():               Destroys all items in reverse order.


	--- Notes

	- Dependencies should flow downward. A stream's dependencies should live at
	  least as long as it does. A short-lived scope reading from a long-lived scope is safe;
	  the reverse might cause the dependent to go stale.

	- Do not create Computed streams inside another Computed's callback

	- Circular dependencies (A -> B -> A) are detected at runtime and will throw an error with
	  diagnostic information
]]


local RunService = game:GetService("RunService")

local IsClient: boolean = RunService:IsClient()


--[[ ── Types ────────────────────────────────────────────────────────────── ]]

-- Cleanup / disconnect handle returned by listeners, bindings, etc.
type Disconnect = () -> ()

-- Callback signatures
type ChangeCallback = (oldValue: any, newValue: any) -> ()
type ObserveCallback = (value: any) -> Disconnect?

-- Properties table passed to Bind / Listen
type PropertiesTable = { [any]: any }

-- Anything a Scope can clean up
type Cleanable = Disconnect
| RBXScriptConnection
| Instance
| thread
| { Destroy: (self: any) -> () }
| { Disconnect: (self: any) -> () }

-- Any object that can be added to a Scope via :Add() and returned transparently
type Addable = Cleanable | any


-- ── Debug ──

type DebugObjectInfo = {
	index: number,
	type: string,
	source: string,
	line: number,
	fullSource: string,
	scope: any?,
	createdAt: number,
	name: string?,
	category: string?,
	displayName: string?,
	updateCount: number,
	lastUpdateTime: number?,
	lastTriggeredBy: any?,
	allDeps: { [any]: boolean }?,
	allListeners: { [any]: boolean }?,
}

type DebugCallbackInfo = {
	source: string,
	line: number,
	fullSource: string,
}

type DebugLogEntry = {
	time: number,
	index: number,
	ref: string,
	objType: string,
	oldStr: string,
	newStr: string,
	triggeredByRef: string?,
}

type DebugState = {
	objects: { [any]: DebugObjectInfo },
	callbacks: { [number]: DebugCallbackInfo },
	counter: number,
	names: { [string]: { [number]: string } }?,
	namesByShort: { [string]: { [number]: string } }?,
	log: { DebugLogEntry },
}

type DebugWidget = {
	Visible: any,
	Open: (self: DebugWidget) -> (),
	Close: (self: DebugWidget) -> (),
}


-- ── Internal implementation shapes ──

-- The raw table shape created by _createValue / setmetatable
type StreamValueImpl = {
	_type: "StreamValue",
	_value: any,
	_listeners: { [any]: any },
}

-- The raw table shape created by _createComputed / setmetatable
type StreamComputedValueImpl = {
	_type: "StreamComputedValue",
	_value: any,
	_callback: (() -> any)?,
	_listeners: { [any]: any },
	_listening: { [any]: number },
	_evalCounter: number?,
}

-- The raw table shape created by _createScope / setmetatable
type StreamScopeImpl = {
	_type: "StreamScope",
	_items: { any },
	_destroyed: boolean,
}


-- ── Public export types (consumer‑facing) ──

export type StreamValue = {
	get: (self: StreamValue) -> any,
	set: (self: StreamValue, value: any) -> (),
	Destroy: (self: StreamValue) -> (),
}

export type StreamComputedValue = {
	get: (self: StreamComputedValue) -> any,
	Destroy: (self: StreamComputedValue) -> (),
}

export type StreamObject = StreamValue | StreamComputedValue

export type StreamScope = {
	Add: <T>(self: StreamScope, item: T) -> T,
	InnerScope: (self: StreamScope, category: string?, displayName: string?) -> StreamScope,
	Value: (self: StreamScope, value: any) -> StreamValue,
	Computed: (self: StreamScope, callback: () -> any) -> StreamComputedValue,
	Bind: (self: StreamScope, target: Instance | { [any]: any }) -> (propertiesTable: PropertiesTable) -> Disconnect,
	Observe: (self: StreamScope, target: StreamObject, callback: ObserveCallback) -> Disconnect,
	Listen: (self: StreamScope, target: any, args: ((...any) -> ...any)?) -> any,
	FromProperty: (self: StreamScope, instance: Instance, prop: string) -> StreamValue,
	FromValueBase: (self: StreamScope, valueBase: ValueBase) -> StreamValue,
	FromAttribute: (instance: Instance, attributeName: string, callback: ChangeCallback?) -> (StreamValue, Disconnect),
	Destroy: (self: StreamScope) -> (),
}

export type StreamModule = {
	-- Key helpers
	Event: { [string]: string },
	Attribute: { [string]: string },
	Changed: { [string]: string },

	-- Configuration
	PermittedDebugRoles: { string },
	_debug: DebugState?,

	-- Core API
	Value: (value: any) -> StreamValue,
	Computed: (callback: () -> any) -> StreamComputedValue,
	Listen: (target: any, args: any?) -> any,
	Observe: (target: StreamObject, callback: ObserveCallback) -> Disconnect,
	Bind: (target: Instance | { [any]: any }) -> (propertiesTable: PropertiesTable) -> Disconnect,
	New: (instance: string | (...any) -> any, ...any) -> (propertiesTable: PropertiesTable) -> (any, Disconnect),

	-- Utility
	BindToInstanceProperty: (stateObject: StreamValue, instance: Instance, prop: string) -> Disconnect,
	FromProperty: (instance: Instance, prop: string) -> (StreamValue, Disconnect),
	FromValueBase: (valueBase: ValueBase) -> (StreamValue, Disconnect),
	FromAttribute: (instance: Instance, attributeName: string, maid: any, callback: ChangeCallback?) -> StreamValue,

	-- Scope
	Scope: (category: string?, displayName: string?) -> StreamScope,

	-- Debug
	EnableDebug: (Iris: any) -> DebugWidget?,
}


--[[ ── Implementation ───────────────────────────────────────────────────── ]]

local Stream = {
	Event = {},
	Attribute = {},
	Changed = {},
	PermittedDebugRoles = { "Developer" },
} :: StreamModule

setmetatable(Stream.Event, { __index = function(_: any, i: string): string return "Event_" .. i end })
setmetatable(Stream.Attribute, { __index = function(_: any, i: string): string return "Attribute_" .. i end })
setmetatable(Stream.Changed, { __index = function(_: any, i: string): string return "Changed_" .. i end })

local CustomListeners: { [any]: { [string]: { [number]: (...any) -> ...any, count: number } } } = setmetatable({}, { __mode = "k" }) :: any
local WeakMap: { [number]: any } = setmetatable({}, { __mode = "kv" }) :: any
local ChangePushRequested: boolean = false
local RunningComputed: StreamComputedValueImpl? = nil
local UniqueCounter: number = 1000
local IsListenBind: boolean? = false
local PendingChanges2: { [StreamValueImpl | StreamComputedValueImpl]: any } = {}
local PendingChanges: { [StreamValueImpl | StreamComputedValueImpl]: any } = {}
local NilValue: {} = {}

local CycleCounter: number = 0
local MAX_PUSHES: number = 100

local DEBUG_ENABLED: boolean = false
Stream._debug = nil


-- ── Debug helpers ──

local function debugRegister(obj: any, objType: string, source: string?, line: number?, category: string?, displayName: string?)
	if not DEBUG_ENABLED then return end
	local dbg: DebugState = Stream._debug :: DebugState
	dbg.counter += 1
	local short: string = if source then (source:match("([^%.]+)$") or source) else "unknown"

	local name: string? = nil
	if dbg.names and source then
		local scriptNames: { [number]: string }? = dbg.names[source] or (dbg.namesByShort and (dbg.namesByShort :: { [string]: { [number]: string } })[short])
		if scriptNames and line then
			name = scriptNames[line]
		end
	end

	dbg.objects[obj] = {
		index = dbg.counter,
		type = objType,
		source = short,
		line = line or 0,
		fullSource = source or "unknown",
		scope = nil,
		createdAt = os.clock(),
		name = name,
		category = category,
		displayName = displayName,
		updateCount = 0,
		lastUpdateTime = nil,
		lastTriggeredBy = nil,
	}
end

local function debugUnregister(obj: any)
	if not DEBUG_ENABLED then return end
	local dbg: DebugState = Stream._debug :: DebugState
	local info: DebugObjectInfo? = dbg.objects[obj]
	if info and info.allDeps then
		for target in info.allDeps :: { [any]: boolean } do
			local targetInfo: DebugObjectInfo? = dbg.objects[target]
			if targetInfo and targetInfo.allListeners then
				(targetInfo.allListeners :: { [any]: boolean })[obj] = nil
			end
		end
	end
	dbg.objects[obj] = nil
end

function Stream.EnableDebug(Iris): DebugWidget?
	if DEBUG_ENABLED then return nil end
	DEBUG_ENABLED = true
	Stream._debug = {
		objects = {},
		callbacks = {},
		counter = 0,
		names = nil,
		log = {},
	} :: DebugState

	local dbg: DebugState = Stream._debug :: DebugState

	local DebugNames: Instance? = script:FindFirstChild("StreamDebug_VariableNames")
	if DebugNames then
		dbg.names = require(DebugNames :: ModuleScript)
	else
		dbg.names = {}
	end

	-- Build short-name fallback index (StarterPlayerScripts becomes Players.X at runtime)
	local byShort: { [string]: { [number]: string } } = {}
	for path: string, lineMap: { [number]: string } in dbg.names :: { [string]: { [number]: string } } do
		local shortName: string? = path:match("([^%.]+)$")
		if shortName then
			byShort[shortName] = lineMap
		end
	end
	dbg.namesByShort = byShort

	local DebugModule: Instance? = script:FindFirstChild("StreamDebug")
	if DebugModule then
		local StreamDebug = require(DebugModule :: ModuleScript)

		StreamDebug:ClientInit(Iris)

		StreamDebug.Visible = Iris.State(false)

		local DebugWidgetInstance: DebugWidget = {
			Visible = StreamDebug.Visible,
			Open = function(self: DebugWidget)
				self.Visible:set(true)
			end,
			Close = function(self: DebugWidget)
				self.Visible:set(false)
			end,
		}

		Iris:Connect(function()
			if DebugWidgetInstance.Visible:get() then
				Iris.SetNextWidgetID("StreamDebugExplorer")
				StreamDebug:Render(Iris, Stream._debug)
			end
		end)

		return DebugWidgetInstance
	else
		error(`Stream Debug enabled but the debug module wasn't found! (Expected "StreamDebug" under {script:GetFullName()})`)
	end

	return nil
end


-- ── Stack introspection ──

local function getExternalCaller(): (string?, number?)
	for level = 3, 10 do
		local source: string?, line: number? = debug.info(level, "sl")
		if not source then break end
		if not (source :: string):match("Stream$") then
			return source, line
		end
	end
	return debug.info(3, "sl")
end


-- ── Metatables ──

local StreamValue: { [string]: any } = { _type = "StreamValue" }
StreamValue.__index = StreamValue

local StreamComputedValue: { [string]: any } = { _type = "StreamComputedValue" }
StreamComputedValue.__index = StreamComputedValue


-- ── Internal helpers ──

local function isValueObject(value: any): boolean
	return typeof(value) == "table" and (value._type == "StreamValue" or value._type == "StreamComputedValue")
end

local function onValueChanged(value: any, callback: (...any) -> ...any): Disconnect
	local uniqueId: number = UniqueCounter
	UniqueCounter += 1
	value._listeners[uniqueId] = callback
	WeakMap[uniqueId] = value

	if DEBUG_ENABLED then
		local source: string?, line: number? = getExternalCaller()
		local short: string = if source then ((source :: string):match("([^%.]+)$") or source :: string) else "unknown"
		(Stream._debug :: DebugState).callbacks[uniqueId] = {
			source = short,
			line = line or 0,
			fullSource = source or "unknown",
		}
	end

	return function()
		local val: any = WeakMap[uniqueId]
		if val then
			val._listeners[uniqueId] = nil
			WeakMap[uniqueId] = nil
		end
		if DEBUG_ENABLED then
			(Stream._debug :: DebugState).callbacks[uniqueId] = nil
		end
	end
end

local function applyValue(target: any, propertyName: string, oldValue: any, value: any)
	target[propertyName] = value
	local targetListeners: { [string]: { [number]: (...any) -> ...any, count: number } }? = CustomListeners[target]
	if targetListeners then
		local list = targetListeners[propertyName]
		if list then
			for _, fn: (...any) -> ...any in list do
				task.defer(fn, oldValue, value)
			end
		end
	end
end

local function formatDebugRef(info: DebugObjectInfo): string
	if info.name then
		return string.format("%s.%s", info.source, info.name)
	end
	return string.format("%s:%d", info.source, info.line)
end

local function formatForLog(value: any): string
	if value == nil then return "nil" end
	local ok: boolean, str: string = pcall(function(): string
		local t: string = typeof(value)
		if t == "string" then
			return if #value > 20 then string.format('"%s…"', value:sub(1, 20)) else string.format('"%s"', value)
		elseif t == "number" then
			return if value == math.floor(value) then tostring(value) else string.format("%.4g", value)
		elseif t == "boolean" then
			return tostring(value)
		else
			local s: string = tostring(value)
			return if #s > 20 then s:sub(1, 20) .. "…" else s
		end
	end)
	return if ok then str else "?"
end


-- ── Change propagation ──

local function pushChanges()
	CycleCounter += 1

	if CycleCounter > MAX_PUSHES then
		local involved: { string } = {}
		local seen: { [any]: boolean } = {}

		if DEBUG_ENABLED then
			local dbg: DebugState = Stream._debug :: DebugState
			for target in PendingChanges2 do
				local info: DebugObjectInfo? = dbg.objects[target]
				if info and not seen[target] then
					seen[target] = true
					table.insert(involved, string.format("  %s (%s #%d)", formatDebugRef(info :: DebugObjectInfo), (info :: DebugObjectInfo).type, (info :: DebugObjectInfo).index))
				end
			end
			for target in PendingChanges do
				local info: DebugObjectInfo? = dbg.objects[target]
				if info and not seen[target] then
					seen[target] = true
					table.insert(involved, string.format("  %s (%s #%d)", formatDebugRef(info :: DebugObjectInfo), (info :: DebugObjectInfo).type, (info :: DebugObjectInfo).index))
				end
			end
		end

		table.clear(PendingChanges)
		table.clear(PendingChanges2)
		ChangePushRequested = false
		CycleCounter = 0

		error(string.format(
			"Stream: circular dependency detected after %d cascading updates.\nInvolved:\n%s",
			MAX_PUSHES,
			table.concat(involved, "\n")
			))
	end

	ChangePushRequested = false
	PendingChanges, PendingChanges2 = PendingChanges2, PendingChanges

	if DEBUG_ENABLED then
		local dbg: DebugState = Stream._debug :: DebugState

		for target: any, oldValue: any in PendingChanges2 do
			PendingChanges2[target] = nil

			if oldValue == NilValue then
				oldValue = nil
			end

			if target._value ~= oldValue then
				local info: DebugObjectInfo? = dbg.objects[target]
				if info then
					(info :: DebugObjectInfo).updateCount += 1;
					(info :: DebugObjectInfo).lastUpdateTime = os.clock()

					local log: { DebugLogEntry } = dbg.log
					local triggeredByInfo: DebugObjectInfo? = (info :: DebugObjectInfo).lastTriggeredBy and dbg.objects[(info :: DebugObjectInfo).lastTriggeredBy]
					table.insert(log, {
						time = os.clock(),
						index = (info :: DebugObjectInfo).index,
						ref = formatDebugRef(info :: DebugObjectInfo),
						objType = (info :: DebugObjectInfo).type,
						oldStr = formatForLog(oldValue),
						newStr = formatForLog(target._value),
						triggeredByRef = if triggeredByInfo then formatDebugRef(triggeredByInfo :: DebugObjectInfo) else nil,
					})
					if #log > 200 then
						table.remove(log, 1)
					end
				end

				for listener: any, arg: any in target._listeners do
					if typeof(listener) == "table" then
						local listenerInfo: DebugObjectInfo? = dbg.objects[listener]
						if listenerInfo then
							(listenerInfo :: DebugObjectInfo).lastTriggeredBy = target
						end
						task.spawn(listener._update, listener)
					else
						task.spawn(arg, oldValue, target._value)
					end
				end
			end
		end
	else
		for target: any, oldValue: any in PendingChanges2 do
			PendingChanges2[target] = nil

			if oldValue == NilValue then
				oldValue = nil
			end

			if target._value ~= oldValue then
				for listener: any, arg: any in target._listeners do
					if typeof(listener) == "table" then
						task.spawn(listener._update, listener)
					else
						task.spawn(arg, oldValue, target._value)
					end
				end
			end
		end
	end

	if not ChangePushRequested then
		CycleCounter = 0
	end
end

local function requestPushChanges()
	if not ChangePushRequested then
		ChangePushRequested = true
		task.defer(pushChanges)
	end
end


-- ── StreamValue methods ──

function StreamValue.get(self: StreamValueImpl): any
	if RunningComputed and self._listeners then
		(RunningComputed :: StreamComputedValueImpl)._listening[self] = (RunningComputed :: StreamComputedValueImpl)._evalCounter
	end
	return self._value
end

function StreamValue.set(self: StreamValueImpl, value: any)
	if not self._listeners then return end

	if self._value ~= value then
		if PendingChanges[self] == nil then
			PendingChanges[self] = if self._value == nil then NilValue else self._value
			requestPushChanges()
		end

		self._value = value
	end
end

function StreamValue.Destroy(self: StreamValueImpl)
	if not self._listeners then return end
	for key: any in self._listeners do
		if type(key) == "number" then
			WeakMap[key] = nil
			if DEBUG_ENABLED then
				(Stream._debug :: DebugState).callbacks[key] = nil
			end
		elseif typeof(key) == "table" and key._listening then
			key._listening[self] = nil
		end
	end
	self._listeners = nil :: any
	PendingChanges[self] = nil
	PendingChanges2[self] = nil
	self._value = nil
	debugUnregister(self)
end


-- ── StreamComputedValue methods ──

function StreamComputedValue.get(self: StreamComputedValueImpl): any
	if RunningComputed and self._listeners then
		(RunningComputed :: StreamComputedValueImpl)._listening[self] = (RunningComputed :: StreamComputedValueImpl)._evalCounter
	end
	return self._value
end

function StreamComputedValue._update(self: StreamComputedValueImpl, firstCall: boolean?)
	self._evalCounter = UniqueCounter
	UniqueCounter += 1

	local prev: StreamComputedValueImpl? = RunningComputed
	RunningComputed = self
	local ok: boolean, value: any = pcall(self._callback :: () -> any)
	RunningComputed = prev

	if not ok then
		warn("Stream.Computed error:", value)
		value = self._value
	end

	if DEBUG_ENABLED then
		local dbg: DebugState = Stream._debug :: DebugState
		for target: any, counter: number in self._listening do
			if counter == self._evalCounter then
				target._listeners[self] = true
				local targetInfo: DebugObjectInfo? = dbg.objects[target]
				if targetInfo then
					if not (targetInfo :: DebugObjectInfo).allListeners then (targetInfo :: DebugObjectInfo).allListeners = {} end;
					((targetInfo :: DebugObjectInfo).allListeners :: { [any]: boolean })[self] = true
				end
				local selfInfo: DebugObjectInfo? = dbg.objects[self]
				if selfInfo then
					if not (selfInfo :: DebugObjectInfo).allDeps then (selfInfo :: DebugObjectInfo).allDeps = {} end;
					((selfInfo :: DebugObjectInfo).allDeps :: { [any]: boolean })[target] = true
				end
			else
				target._listeners[self] = nil
				self._listening[target] = nil
			end
		end
	else
		for target: any, counter: number in self._listening do
			if counter == self._evalCounter then
				target._listeners[self] = true
			else
				target._listeners[self] = nil
				self._listening[target] = nil
			end
		end
	end

	self._evalCounter = nil

	if self._value ~= value then
		if not firstCall and PendingChanges[self] == nil then
			PendingChanges[self] = if self._value == nil then NilValue else self._value
			requestPushChanges()
		end

		self._value = value
	end
end

function StreamComputedValue.Destroy(self: StreamComputedValueImpl)
	for target: any in self._listening do
		if target._listeners then
			target._listeners[self] = nil
		end
	end
	self._listening = nil :: any

	for key: any in self._listeners do
		if type(key) == "number" then
			WeakMap[key] = nil
			if DEBUG_ENABLED then
				(Stream._debug :: DebugState).callbacks[key] = nil
			end
		elseif typeof(key) == "table" and key._listening then
			key._listening[self] = nil
		end
	end
	self._listeners = nil :: any

	PendingChanges[self] = nil
	PendingChanges2[self] = nil
	self._callback = nil
	self._value = nil
	self._evalCounter = nil
	debugUnregister(self)
end


-- ── Factory functions ──

local function _createValue(value: any, source: string?, line: number?): StreamValueImpl
	local sv: StreamValueImpl = setmetatable({ _value = value, _listeners = {} }, StreamValue) :: any
	debugRegister(sv, "Value", source, line)
	return sv
end

local function _createComputed(callback: () -> any, source: string?, line: number?): StreamComputedValueImpl
	local computed: StreamComputedValueImpl = setmetatable({ _callback = callback, _listeners = {}, _listening = {} }, StreamComputedValue) :: any
	debugRegister(computed, "Computed", source, line)
	computed:_update(true)
	return computed
end

function Stream.Value(value: any): StreamValue
	if DEBUG_ENABLED then
		return _createValue(value, debug.info(2, "sl")) :: any
	end
	return _createValue(value) :: any
end

function Stream.Computed(callback: () -> any): StreamComputedValue
	if DEBUG_ENABLED then
		return _createComputed(callback, debug.info(2, "sl")) :: any
	end
	return _createComputed(callback) :: any
end


-- ── Core API ──

function Stream.Listen(target: any, args: any?): any
	if isValueObject(target) then
		return onValueChanged(target, args)
	end

	IsListenBind = true
	return Stream.Bind(target)
end

function Stream.Observe(target: any, callback: ObserveCallback): Disconnect
	local cleanup: Disconnect? = nil

	local function run(value: any)
		if cleanup then
			(cleanup :: Disconnect)()
			cleanup = nil
		end
		local result: any = callback(value)
		if type(result) == "function" then
			cleanup = result
		end
	end

	run(target._value)

	local disconnect: Disconnect = onValueChanged(target, function(_oldValue: any, newValue: any)
		run(newValue)
	end)

	return function()
		disconnect()
		if cleanup then
			(cleanup :: Disconnect)()
			cleanup = nil
		end
	end
end

function Stream.New(instance: any, ...: any): (propertiesTable: PropertiesTable) -> (any, Disconnect)
	local newClass: any

	if typeof(instance) == "function" then
		newClass = instance(...)
		assert(typeof(newClass) == "table", "The constructed class from Stream.New must be a table!")
	elseif typeof(instance) == "string" then
		newClass = Instance.new(instance, ...)
	else
		error("Stream.New only takes in an instance string or a constructor!")
	end

	return function(propertiesTable: PropertiesTable): (any, Disconnect)
		local cleanup: Disconnect = Stream.Bind(newClass)(propertiesTable)
		return newClass, cleanup
	end
end

function Stream.Bind(target: any): (propertiesTable: PropertiesTable) -> Disconnect
	local isListenBind: boolean? = IsListenBind
	IsListenBind = nil

	local isTable: boolean = typeof(target) == "table"
	local isInstance: boolean = typeof(target) == "Instance"
	assert(isInstance or isTable, "Stream.Bind only accepts instances or tables!")

	return function(propertiesTable: PropertiesTable): Disconnect
		local cleanup: { Disconnect | RBXScriptConnection } = {}

		local targetListeners: { [string]: { [number]: (...any) -> ...any, count: number } }?
		local listeners: { string }?
		local uniqueId: number?

		for propertyName: any, value: any in propertiesTable do
			if isValueObject(propertyName) then
				table.insert(cleanup, (onValueChanged(propertyName, value)))
				continue
			end

			if isInstance then
				if (propertyName :: string):sub(1, 6) == "Event_" then
					table.insert(cleanup, target[(propertyName :: string):sub(7)]:Connect(value))
					continue
				elseif (propertyName :: string):sub(1, 10) == "Attribute_" then
					local attributeName: string = (propertyName :: string):sub(11)
					local oldValue: any = target:GetAttribute(attributeName)

					local event: RBXScriptConnection = target:GetAttributeChangedSignal(attributeName):Connect(function()
						local newValue: any = target:GetAttribute(attributeName)
						value(oldValue, newValue)
						oldValue = newValue
					end)

					table.insert(cleanup, event)
					continue
				elseif (propertyName :: string):sub(1, 8) == "Changed_" then
					local propName: string = (propertyName :: string):sub(9)
					local oldValue: any = target[propName]

					local event: RBXScriptConnection = target:GetPropertyChangedSignal(propName):Connect(function()
						local newValue: any = target[propName]
						value(oldValue, newValue)
						oldValue = newValue
					end)

					table.insert(cleanup, event)
					continue
				end
			end

			if isListenBind then
				if isInstance then
					table.insert(cleanup, target:GetPropertyChangedSignal(propertyName):Connect(value))
					continue
				end

				if type(value) == "function" then
					if not targetListeners then
						targetListeners = CustomListeners[target]

						if not targetListeners then
							targetListeners = {}
							CustomListeners[target] = targetListeners
						end

						listeners = {}

						uniqueId = UniqueCounter
						UniqueCounter += 1

						WeakMap[uniqueId :: number] = target
					end

					local list: any = (targetListeners :: any)[propertyName]

					if not list then
						list = { count = 0 }
						;(targetListeners :: any)[propertyName] = list
					end

					list[uniqueId :: number] = value
					list.count += 1

					table.insert(listeners :: { string }, propertyName)
				end
			else
				if isValueObject(value) then
					applyValue(target, propertyName, nil, value:get())

					table.insert(cleanup, (onValueChanged(value, function(oldValue: any, newValue: any)
						applyValue(target, propertyName, oldValue, newValue)
					end)))
				else
					applyValue(target, propertyName, nil, value)
				end
			end
		end

		return function()
			if cleanup then
				local _cleanup: { Disconnect | RBXScriptConnection } = cleanup
				cleanup = nil :: any

				for _: number, thing: any in _cleanup do
					if type(thing) == "function" then
						task.spawn(thing)
					else
						thing:Disconnect()
					end
				end

				if uniqueId then
					local boundTarget: any = WeakMap[uniqueId :: number]
					WeakMap[uniqueId :: number] = nil

					if boundTarget then
						local tl: any = CustomListeners[boundTarget]

						if tl then
							for _: number, key: string in listeners :: { string } do
								local list: any = tl[key]

								if list and list[uniqueId :: number] then
									list[uniqueId :: number] = nil
									list.count -= 1

									if list.count == 0 then
										tl[key] = nil

										if next(tl) == nil then
											CustomListeners[boundTarget] = nil
										end
									end
								end
							end
						end
					end

					listeners = nil
				end
			end
		end
	end
end


-- ── Utility ──

function Stream.BindToInstanceProperty(stateObject: StreamValue, instance: Instance, prop: string): Disconnect
	return Stream.Bind(instance)({
		[Stream.Changed[prop]] = function(_: any, new: any)
			stateObject:set(new)
		end,
	})
end

function Stream.FromProperty(instance: Instance, prop: string): (StreamValue, Disconnect)
	local streamVal: StreamValueImpl
	if DEBUG_ENABLED then
		streamVal = _createValue(instance[prop], debug.info(2, "sl"))
	else
		streamVal = _createValue(instance[prop])
	end
	return streamVal :: any, Stream.BindToInstanceProperty(streamVal :: any, instance, prop)
end

function Stream.FromValueBase(valueBase: ValueBase): (StreamValue, Disconnect)
	local streamVal: StreamValueImpl
	if DEBUG_ENABLED then
		streamVal = _createValue((valueBase :: any).Value, debug.info(2, "sl"))
	else
		streamVal = _createValue((valueBase :: any).Value)
	end
	return streamVal :: any, Stream.BindToInstanceProperty(streamVal :: any, valueBase :: any, "Value")
end

function Stream.FromAttribute(instance: Instance, attributeName: string, callback: ChangeCallback?): (StreamValue, Disconnect)
	local currentValue: any = instance:GetAttribute(attributeName)
	local streamVal: StreamValueImpl
	if DEBUG_ENABLED then
		streamVal = _createValue(currentValue, debug.info(2, "sl"))
	else
		streamVal = _createValue(currentValue)
	end

	local disconnect: Disconnect = Stream.Bind(instance)({
		[Stream.Attribute[attributeName]] = function(old: any, new: any)
			(streamVal :: any):set(new)
			if callback then
				(callback :: ChangeCallback)(old, new)
			end
		end,
	})

	if callback then
		(callback :: ChangeCallback)(nil, currentValue)
	end

	return streamVal :: any, disconnect
end
-- ── StreamScope ──

local StreamScope: { [string]: any } = { _type = "StreamScope" }
StreamScope.__index = StreamScope

local function _createScope(source: string?, line: number?, category: string?, displayName: string?): StreamScopeImpl
	local scope: StreamScopeImpl = setmetatable({
		_items = {},
		_destroyed = false,
	}, StreamScope) :: any
	debugRegister(scope, "Scope", source, line, category, displayName)
	return scope
end

function Stream.Scope(category: string?, displayName: string?): StreamScope
	if DEBUG_ENABLED then
		local source: string?, line: number? = debug.info(2, "sl")
		return _createScope(source, line, category, displayName) :: any
	end
	return _createScope(nil, nil, category, displayName) :: any
end

function StreamScope.Add(self: StreamScopeImpl, item: any): any
	if self._destroyed then
		warn("Stream.Scope: attempted to add to a destroyed scope")
		return item
	end
	table.insert(self._items, item)
	if DEBUG_ENABLED then
		local info: DebugObjectInfo? = (Stream._debug :: DebugState).objects[item]
		if info then
			(info :: DebugObjectInfo).scope = self
		end
	end
	return item
end

function StreamScope.InnerScope(self: StreamScopeImpl, category: string?, displayName: string?): StreamScopeImpl
	local inner: StreamScopeImpl
	if DEBUG_ENABLED then
		local source: string?, line: number? = debug.info(2, "sl")
		inner = _createScope(source, line, category, displayName)
	else
		inner = _createScope(nil, nil, category, displayName)
	end
	StreamScope.Add(self, inner)
	return inner
end

function StreamScope.Value(self: StreamScopeImpl, value: any): StreamValueImpl
	if DEBUG_ENABLED then
		return StreamScope.Add(self, _createValue(value, debug.info(2, "sl")))
	end
	return StreamScope.Add(self, _createValue(value))
end

function StreamScope.Computed(self: StreamScopeImpl, callback: () -> any): StreamComputedValueImpl
	if DEBUG_ENABLED then
		return StreamScope.Add(self, _createComputed(callback, debug.info(2, "sl")))
	end
	return StreamScope.Add(self, _createComputed(callback))
end

function StreamScope.Bind(self: StreamScopeImpl, target: any): (propertiesTable: PropertiesTable) -> Disconnect
	local bindFn: (propertiesTable: PropertiesTable) -> Disconnect = Stream.Bind(target)
	return function(propertiesTable: PropertiesTable): Disconnect
		return StreamScope.Add(self, bindFn(propertiesTable))
	end
end

function StreamScope.Observe(self: StreamScopeImpl, target: any, callback: ObserveCallback): Disconnect
	return StreamScope.Add(self, Stream.Observe(target, callback))
end

function StreamScope.Listen(self: StreamScopeImpl, target: any, args: any?): any
	if args ~= nil then
		return StreamScope.Add(self, Stream.Listen(target, args))
	end
	local bindFn: any = Stream.Listen(target)
	return function(propertiesTable: PropertiesTable): Disconnect
		return StreamScope.Add(self, bindFn(propertiesTable))
	end
end

function StreamScope.FromProperty(self: StreamScopeImpl, instance: Instance, prop: string): StreamValueImpl
	local streamVal: StreamValueImpl
	if DEBUG_ENABLED then
		streamVal = _createValue(instance[prop], debug.info(2, "sl"))
	else
		streamVal = _createValue(instance[prop])
	end
	StreamScope.Add(self, Stream.BindToInstanceProperty(streamVal :: any, instance, prop))
	return StreamScope.Add(self, streamVal)
end

function StreamScope.FromValueBase(self: StreamScopeImpl, valueBase: ValueBase): StreamValueImpl
	local streamVal: StreamValueImpl
	if DEBUG_ENABLED then
		streamVal = _createValue((valueBase :: any).Value, debug.info(2, "sl"))
	else
		streamVal = _createValue((valueBase :: any).Value)
	end
	StreamScope.Add(self, Stream.BindToInstanceProperty(streamVal :: any, valueBase :: any, "Value"))
	return StreamScope.Add(self, streamVal)
end

function StreamScope.FromAttribute(self: StreamScopeImpl, instance: Instance, attributeName: string, callback: ChangeCallback?): StreamValueImpl
	local currentValue: any = instance:GetAttribute(attributeName)
	local streamVal: StreamValueImpl
	if DEBUG_ENABLED then
		streamVal = _createValue(currentValue, debug.info(2, "sl"))
	else
		streamVal = _createValue(currentValue)
	end

	StreamScope.Add(self, Stream.Bind(instance)({
		[Stream.Attribute[attributeName]] = function(old: any, new: any)
			(streamVal :: any):set(new)
			if callback then
				(callback :: ChangeCallback)(old, new)
			end
		end,
	}))

	if callback then
		(callback :: ChangeCallback)(nil, currentValue)
	end

	return StreamScope.Add(self, streamVal)
end

function StreamScope.Destroy(self: StreamScopeImpl)
	if self._destroyed then return end
	self._destroyed = true
	local items: { any } = self._items
	for i: number = #items, 1, -1 do
		local item: any = items[i]
		local t: string = typeof(item)
		if t == "function" then
			task.spawn(item)
		elseif t == "RBXScriptConnection" then
			item:Disconnect()
		elseif t == "Instance" then
			item:Destroy()
		elseif t == "thread" then
			task.cancel(item)
		elseif t == "table" then
			if type(item.Destroy) == "function" then
				item:Destroy()
			elseif type(item.Disconnect) == "function" then
				item:Disconnect()
			end
		end
		items[i] = nil
	end
	debugUnregister(self)
end

return Stream
