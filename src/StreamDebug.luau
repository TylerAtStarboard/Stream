local ReplicatedStorage = game:GetService("ReplicatedStorage")


-- Strip out the leading path for script sources

const SOURCE_PREFIXES = {
	"ReplicatedStorage.ClientModules.",
	"ReplicatedStorage.SharedModules.",
	"ServerStorage.ServerModules.",
}

-- Constants

const ICON_COLORS = {
	Value    = Color3.fromRGB(74, 158, 232),
	Computed = Color3.fromRGB(155, 89, 182),
	Scope    = Color3.fromRGB(232, 169, 74),
	Leaked   = Color3.fromRGB(232, 74, 74),
	Callback = Color3.fromRGB(74, 232, 123),
	Category = Color3.fromRGB(120, 120, 120),
}

const ICON_LETTERS = {
	Value    = "V",
	Computed = "C",
	Scope    = "S",
	Leaked   = "!",
	Callback = "ƒ",
	Category = "▪",
}

const VALUE_TEXT_COLOR = Color3.fromRGB(106, 199, 137)
const VALUE_TEXT_HEX = "#6AC789"

local function richIcon(objType)
	local c = ICON_COLORS[objType] or ICON_COLORS.Category
	return string.format(
		'<font color="#%02X%02X%02X">■</font>',
		math.floor(c.R * 255),
		math.floor(c.G * 255),
		math.floor(c.B * 255)
	)
end

local function stripSource(source)
	for _, prefix in SOURCE_PREFIXES do
		if source:sub(1, #prefix) == prefix then
			return source:sub(#prefix + 1)
		end
	end
	return source
end


local widgetsRegistered = false

local function registerWidgets(Iris)
	if widgetsRegistered then
		return
	end
	widgetsRegistered = true

	local Internal = Iris.Internal
	local widgets = Internal._utility

	Internal.WidgetConstructor("ExplorerItem", {
		hasState = true,
		hasChildren = false,
		Args = {
			["Text"] = 1,
			["Index"] = 2,
			["IconColor"] = 3,
			["IconText"] = 4,
			["ValueText"] = 5,
		},
		Events = {
			["selected"] = {
				["Init"] = function(_thisWidget) end,
				["Get"] = function(thisWidget)
					return thisWidget.lastSelectedTick == Internal._cycleTick
				end,
			},
			["unselected"] = {
				["Init"] = function(_thisWidget) end,
				["Get"] = function(thisWidget)
					return thisWidget.lastUnselectedTick == Internal._cycleTick
				end,
			},
			["active"] = {
				["Init"] = function(_thisWidget) end,
				["Get"] = function(thisWidget)
					return thisWidget.state.index.value == thisWidget.arguments.Index
				end,
			},
			["clicked"] = widgets.EVENTS.click(function(thisWidget)
				return thisWidget.Instance.RowButton
			end),
			["hovered"] = widgets.EVENTS.hover(function(thisWidget)
				return thisWidget.Instance.RowButton
			end),
		},
		Generate = function(thisWidget)
			local Row = Instance.new("Frame")
			Row.Name = "Iris_ExplorerItem"
			Row.Size = UDim2.new(
				Internal._config.ItemWidth,
				UDim.new(0, Internal._config.TextSize + 2 * Internal._config.FramePadding.Y - Internal._config.ItemSpacing.Y)
			)
			Row.BackgroundTransparency = 1
			Row.BorderSizePixel = 0
			Row.ZIndex = 0
			Row.LayoutOrder = thisWidget.ZIndex

			local RowButton = Instance.new("TextButton")
			RowButton.Name = "RowButton"
			RowButton.Size = UDim2.new(1, 0, 0, Internal._config.TextSize + 2 * Internal._config.FramePadding.Y)
			RowButton.Position = UDim2.fromOffset(0, -bit32.rshift(Internal._config.ItemSpacing.Y, 1))
			RowButton.BackgroundColor3 = Internal._config.HeaderColor
			RowButton.BackgroundTransparency = 1
			RowButton.BorderSizePixel = 0
			RowButton.Text = ""
			RowButton.AutoButtonColor = false
			RowButton.ClipsDescendants = true

			widgets.applyFrameStyle(RowButton, false, false)
			widgets.UISizeConstraint(RowButton, Vector2.xAxis)

			local rowPad = RowButton:FindFirstChildOfClass("UIPadding")
			if rowPad then
				rowPad.PaddingTop = UDim.new(0, 0)
				rowPad.PaddingBottom = UDim.new(0, 0)
			end

			local layout = widgets.UIListLayout(RowButton, Enum.FillDirection.Horizontal, UDim.new(0, Internal._config.ItemInnerSpacing.X))
			layout.VerticalAlignment = Enum.VerticalAlignment.Center

			local iconSize = math.floor(Internal._config.TextSize * 0.9)
			local Icon = Instance.new("Frame")
			Icon.Name = "Icon"
			Icon.Size = UDim2.fromOffset(iconSize, iconSize)
			Icon.BackgroundColor3 = ICON_COLORS.Value
			Icon.BorderSizePixel = 0

			local iconCorner = Instance.new("UICorner")
			iconCorner.CornerRadius = UDim.new(0, 3)
			iconCorner.Parent = Icon

			local IconLabel = Instance.new("TextLabel")
			IconLabel.Name = "IconLabel"
			IconLabel.Size = UDim2.fromScale(1, 1)
			IconLabel.BackgroundTransparency = 1
			IconLabel.BorderSizePixel = 0
			IconLabel.Text = "V"
			IconLabel.TextColor3 = Color3.new(1, 1, 1)
			IconLabel.TextSize = 8
			IconLabel.FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold)
			IconLabel.TextXAlignment = Enum.TextXAlignment.Center
			IconLabel.TextYAlignment = Enum.TextYAlignment.Center

			local IconPadding = Instance.new("UIPadding")
			IconPadding.Name = "IconPadding"
			IconPadding.Parent = IconLabel

			IconLabel.Parent = Icon
			Icon.Parent = RowButton

			local TextLabel = Instance.new("TextLabel")
			TextLabel.Name = "TextLabel"
			TextLabel.Size = UDim2.fromOffset(0, 0)
			TextLabel.AutomaticSize = Enum.AutomaticSize.XY
			TextLabel.BackgroundTransparency = 1
			TextLabel.BorderSizePixel = 0
			TextLabel.LayoutOrder = 1
			widgets.applyTextStyle(TextLabel)
			TextLabel.Parent = RowButton

			local ValueLabel = Instance.new("TextLabel")
			ValueLabel.Name = "ValueLabel"
			ValueLabel.Size = UDim2.fromOffset(0, 0)
			ValueLabel.AutomaticSize = Enum.AutomaticSize.XY
			ValueLabel.BackgroundTransparency = 1
			ValueLabel.BorderSizePixel = 0
			ValueLabel.LayoutOrder = 2
			widgets.applyTextStyle(ValueLabel)
			ValueLabel.TextColor3 = VALUE_TEXT_COLOR
			ValueLabel.TextTransparency = 0
			ValueLabel.Parent = RowButton

			thisWidget.ButtonColors = {
				Color = Internal._config.HeaderColor,
				Transparency = 1,
				HoveredColor = Internal._config.HeaderHoveredColor,
				HoveredTransparency = Internal._config.HeaderHoveredTransparency,
				ActiveColor = Internal._config.HeaderActiveColor,
				ActiveTransparency = Internal._config.HeaderActiveTransparency,
			}
			widgets.applyInteractionHighlights("Background", RowButton, RowButton, thisWidget.ButtonColors)

			widgets.applyButtonClick(RowButton, function()
				if type(thisWidget.state.index.value) == "boolean" then
					thisWidget.state.index:set(not thisWidget.state.index.value)
				else
					thisWidget.state.index:set(thisWidget.arguments.Index)
				end
			end)

			RowButton.Parent = Row
			return Row
		end,
		Update = function(thisWidget)
			local Row = thisWidget.Instance
			local RowButton = Row.RowButton
			local TextLabel = RowButton.TextLabel
			local ValueLabel = RowButton.ValueLabel
			local Icon = RowButton.Icon
			local IconLabel = Icon.IconLabel
			local IconPadding = IconLabel.IconPadding

			TextLabel.Text = thisWidget.arguments.Text or "Item"
			if thisWidget.arguments.IconColor then
				Icon.BackgroundColor3 = thisWidget.arguments.IconColor
			end
			if thisWidget.arguments.IconText then
				IconLabel.Text = thisWidget.arguments.IconText
				if thisWidget.arguments.IconText == "C" then
					IconPadding.PaddingRight = UDim.new(0, 1)
				else
					IconPadding.PaddingRight = UDim.new(0, 0)
				end
			end
			if thisWidget.arguments.ValueText and thisWidget.arguments.ValueText ~= "" then
				ValueLabel.Text = "= " .. thisWidget.arguments.ValueText
				ValueLabel.Visible = true
			else
				ValueLabel.Text = ""
				ValueLabel.Visible = false
			end
		end,
		Discard = function(thisWidget)
			thisWidget.Instance:Destroy()
			widgets.discardState(thisWidget)
		end,
		GenerateState = function(thisWidget)
			if thisWidget.state.index == nil then
				if thisWidget.arguments.Index ~= nil then
					error("A shared state index is required for ExplorerItem with an Index argument.", 5)
				end
				thisWidget.state.index = Internal._widgetState(thisWidget, "index", false)
			end
		end,
		UpdateState = function(thisWidget)
			local Row = thisWidget.Instance
			local RowButton = Row.RowButton
			if thisWidget.state.index.value == (thisWidget.arguments.Index or true) then
				thisWidget.ButtonColors.Transparency = Internal._config.HeaderTransparency
				RowButton.BackgroundTransparency = Internal._config.HeaderTransparency
				thisWidget.lastSelectedTick = Internal._cycleTick + 1
			else
				thisWidget.ButtonColors.Transparency = 1
				RowButton.BackgroundTransparency = 1
				thisWidget.lastUnselectedTick = Internal._cycleTick + 1
			end
		end,
	})

	Iris.ExplorerItem = function(arguments, states)
		return Internal._Insert("ExplorerItem", arguments, states)
	end
end


local StreamDebug = {
	_navStack = {},
}

function StreamDebug:ClientInit(Iris)
	registerWidgets(Iris)
	self.Position = Iris.State(Vector2.new(20, 31))
	self.Size = Iris.State(Vector2.new(381, 355))
	self.InspectorPos = Iris.State(Vector2.new(20, 393))
	self.InspectorSize = Iris.State(Vector2.new(380, 292))
end


function StreamDebug:FormatValue(value)
	if value == nil then
		return "nil"
	end
	local ok, str = pcall(function()
		local t = typeof(value)
		if t == "string" then
			return #value > 28 and string.format('"%s…"', value:sub(1, 28)) or string.format('"%s"', value)
		elseif t == "number" then
			return if value == math.floor(value) then tostring(value) else string.format("%.4g", value)
		elseif t == "boolean" then
			return tostring(value)
		elseif t == "table" then
			local count = 0
			for _ in value do count += 1 end
			return string.format("{%d}", count)
		elseif t == "Instance" then
			return string.format('%s "%s"', value.ClassName, value.Name)
		else
			local s = tostring(value)
			return #s > 28 and s:sub(1, 28) .. "…" or s
		end
	end)
	return ok and str or "<error>"
end

function StreamDebug:FormatAge(createdAt)
	local age = os.clock() - createdAt
	if age < 1 then
		return string.format("%.0fms", age * 1000)
	elseif age < 60 then
		return string.format("%.1fs", age)
	else
		return string.format("%.1fm", age / 60)
	end
end

function StreamDebug:CountTable(t)
	local n = 0
	if t then for _ in t do n += 1 end end
	return n
end

function StreamDebug:FormatRef(info)
	if info.name then
		return string.format("%s.%s", info.source, info.name)
	end
	return string.format("%s:%d", info.source, info.line)
end

function StreamDebug:MatchesFilter(info, filter)
	if filter == "" then return true end
	local lower = filter:lower()
	local fields = { info.name, info.source, info.displayName, info.category }
	for _, f in fields do
		if f and f:lower():find(lower, 1, true) then return true end
	end
	return false
end

function StreamDebug:SortRef(info)
	if info.name then
		return info.source .. "." .. info.name
	end
	return info.source .. ":" .. string.format("%04d", info.line)
end

function StreamDebug.ByTypeAndName(self)
	return function(a, b)
		local typeOrder = { Value = 1, Computed = 2, Scope = 0 }
		local aOrder = typeOrder[a.info.type] or 3
		local bOrder = typeOrder[b.info.type] or 3
		if aOrder ~= bOrder then
			return aOrder < bOrder
		end
		local aRef = self:SortRef(a.info)
		local bRef = self:SortRef(b.info)
		if aRef ~= bRef then
			return aRef < bRef
		end
		return a.info.index < b.info.index
	end
end

function StreamDebug:NavigateTo(selectedIdx, targetIndex)
	local current = selectedIdx:get()
	if current ~= 0 then
		table.insert(self._navStack, current)
		if #self._navStack > 32 then
			table.remove(self._navStack, 1)
		end
	end
	selectedIdx:set(targetIndex)
end

function StreamDebug:NavigateBack(selectedIdx)
	while #self._navStack > 0 do
		local prev = table.remove(self._navStack)
		if prev ~= 0 then
			selectedIdx:set(prev)
			return true
		end
	end
	return false
end


function StreamDebug:RenderExplorerItem(Iris, entry, dbg, selectedIdx, leaked)
	local obj = entry.obj
	local info = entry.info
	local iconColor = if leaked then ICON_COLORS.Leaked else (ICON_COLORS[info.type] or ICON_COLORS.Category)
	local iconText = if leaked then ICON_LETTERS.Leaked else (ICON_LETTERS[info.type] or "?")
	local label = self:FormatRef(info)
	local valStr = self:FormatValue(obj._value)
	if info.updateCount and info.updateCount > 0 then
		valStr = string.format("%s  (×%d)", valStr, info.updateCount)
	end

	Iris.PushId(tostring(info.index))
	Iris.ExplorerItem(
		{ label, info.index, iconColor, iconText, valStr },
		{ index = selectedIdx }
	)
	Iris.PopId()
end

function StreamDebug:GetDependents(obj, dbg, useAllTime)
	local dependents = {}
	-- useAllTime: show all dependencies ever observed (for Flow view)
	-- otherwise: show only currently active listeners
	local info = dbg.objects[obj]
	if useAllTime and info and info.allListeners then
		for key in info.allListeners do
			local keyInfo = dbg.objects[key]
			if keyInfo and key._listeners then
				table.insert(dependents, { obj = key, info = keyInfo })
			end
		end
	elseif obj and obj._listeners then
		for key in obj._listeners do
			if typeof(key) == "table" then
				local keyInfo = dbg.objects[key]
				if keyInfo and key._listeners then
					table.insert(dependents, { obj = key, info = keyInfo })
				end
			end
		end
	end
	table.sort(dependents, function(a, b)
		local aRef = if a.info.name then (a.info.source .. "." .. a.info.name) else (a.info.source .. ":" .. a.info.line)
		local bRef = if b.info.name then (b.info.source .. "." .. b.info.name) else (b.info.source .. ":" .. b.info.line)
		if aRef ~= bRef then return aRef < bRef end
		return a.info.index < b.info.index
	end)
	return dependents
end



-- Scopes

function StreamDebug:RenderScopeFolder(Iris, entry, scopeItems, dbg, selectedIdx, filter)
	local scope = entry.obj
	local info = entry.info
	local items = scopeItems[scope] or {}
	local nameLabel = info.displayName or info.name or string.format("#%d", info.index)
	local totalItems = #scope._items

	local visibleItems = {}
	for _, itemEntry in items do
		if self:MatchesFilter(itemEntry.info, filter) then
			table.insert(visibleItems, itemEntry)
		end
	end

	if filter ~= "" and #visibleItems == 0 and not self:MatchesFilter(info, filter) then
		return
	end

	Iris.PushId("s" .. tostring(info.index))
	Iris.PushConfig({ RichText = true })

	Iris.Tree({ string.format(
		'%s %s  <font color="#888888">(%d items, %s)</font>',
		richIcon("Scope"), nameLabel, totalItems, self:FormatAge(info.createdAt)
		)})

	for _, itemEntry in (if filter ~= "" then visibleItems else items) do
		self:RenderExplorerItem(Iris, itemEntry, dbg, selectedIdx, false)
	end

	if filter == "" then
		local otherCounts = {}
		for _, item in scope._items do
			if not dbg.objects[item] then
				local t = typeof(item)
				otherCounts[t] = (otherCounts[t] or 0) + 1
			end
		end
		if next(otherCounts) then
			local parts = {}
			for t, c in otherCounts do table.insert(parts, string.format("%d %s", c, t)) end
			table.sort(parts)
			Iris.Text({ "Other: " .. table.concat(parts, ", "), nil, Color3.fromRGB(120, 120, 120) })
		end
	end

	Iris.End()
	Iris.PopConfig()
	Iris.PopId()
end

function StreamDebug:RenderScopesView(Iris, dbg, data, selectedIdx, filter)
	-- Leaked
	if #data.orphaned > 0 then
		Iris.PushConfig({ RichText = true })
		Iris.PushId("leaked")
		Iris.Tree({ string.format(
			'%s <font color="#E84A4A">Leaked (%d)</font>',
			richIcon("Leaked"), #data.orphaned
			), nil, nil, true })

		Iris.Text({ "Objects whose scope was destroyed but were not cleaned up.", nil, Color3.fromRGB(255, 90, 90) })
		for _, entry in data.orphaned do
			if self:MatchesFilter(entry.info, filter) then
				self:RenderExplorerItem(Iris, entry, dbg, selectedIdx, true)
			end
		end
		Iris.End()
		Iris.PopId()
		Iris.PopConfig()
	end

	-- Categorized scopes
	
	for _, cat in data.categoryOrder do
		local entries = data.categorized[cat]

		if filter ~= "" then
			local anyVisible = false
			for _, entry in entries do
				if self:MatchesFilter(entry.info, filter) then anyVisible = true; break end
				for _, itemEntry in (data.scopeItems[entry.obj] or {}) do
					if self:MatchesFilter(itemEntry.info, filter) then anyVisible = true; break end
				end
				if anyVisible then break end
			end
			if not anyVisible then continue end
		end

		Iris.PushId("cat_" .. cat)
		Iris.PushConfig({ RichText = true })
		Iris.Tree({ string.format("%s %s (%d)", richIcon("Category"), cat, #entries) })
		for _, entry in entries do
			self:RenderScopeFolder(Iris, entry, data.scopeItems, dbg, selectedIdx, filter)
		end
		Iris.End()
		Iris.PopConfig()
		Iris.PopId()
	end

	-- Uncategorized scopes
	for _, entry in data.uncategorizedScopes do
		self:RenderScopeFolder(Iris, entry, data.scopeItems, dbg, selectedIdx, filter)
	end

	-- Unscoped
	local unscopedVisible = {}
	for _, entry in data.unscoped do
		if self:MatchesFilter(entry.info, filter) then
			table.insert(unscopedVisible, entry)
		end
	end
	if #unscopedVisible > 0 then
		Iris.PushId("unscoped")
		Iris.PushConfig({ RichText = true })
		Iris.Tree({ string.format("Unscoped (%d)", #unscopedVisible) })
		for _, entry in unscopedVisible do
			self:RenderExplorerItem(Iris, entry, dbg, selectedIdx, false)
		end
		Iris.End()
		Iris.PopConfig()
		Iris.PopId()
	end
end

-- Flow


function StreamDebug:RenderFlowNode(Iris, entry, dbg, selectedIdx, filter, visited, depth)
	local obj = entry.obj
	local info = entry.info

	-- Guard against destroyed or invalid objects
	if not obj or not info or not dbg.objects[obj] then
		return
	end

	if visited[obj] or depth > 12 then
		return
	end

	local dependents = self:GetDependents(obj, dbg, true)

	if #dependents == 0 then
		-- Leaf node: render as ExplorerItem
		if self:MatchesFilter(info, filter) then
			self:RenderExplorerItem(Iris, entry, dbg, selectedIdx, false)
		end
		return
	end

	-- Non-leaf: render as Tree with dependents as children
	if not self:MatchesFilter(info, filter) then
		-- Check if any descendant matches
		local anyChildMatch = false
		for _, dep in dependents do
			if self:MatchesFilter(dep.info, filter) then
				anyChildMatch = true
				break
			end
		end
		if not anyChildMatch then return end
	end

	visited[obj] = true

	local icon = richIcon(info.type)
	local label = self:FormatRef(info)
	local valStr = self:FormatValue(obj._value)

	local scopeTag = ""
	if info.scope then
		local scopeInfo = dbg.objects[info.scope]
		if scopeInfo then
			local scopeName = scopeInfo.displayName or scopeInfo.name or info.source
			scopeTag = string.format('  <font color="#666666">[%s]</font>', scopeName)
		end
	end

	-- Use a unique ID combining index + depth + parent context
	local nodeId = "f" .. info.index .. "d" .. depth
	Iris.PushId(nodeId)

	local tree = Iris.Tree({ string.format(
		'%s %s  <font color="' .. VALUE_TEXT_HEX .. '">= %s</font>%s',
		icon, label, valStr, scopeTag
		)})

	if tree.collapsed() or tree.uncollapsed() then
		selectedIdx:set(info.index)
	end

	for _, dep in dependents do
		self:RenderFlowNode(Iris, dep, dbg, selectedIdx, filter, visited, depth + 1)
	end

	Iris.End()
	Iris.PopId()

	visited[obj] = nil
end

function StreamDebug:FlowScopeMatchesFilter(roots, dbg, filter)
	for _, root in roots do
		if self:MatchesFilter(root.info, filter) then return true end
		for _, dep in self:GetDependents(root.obj, dbg, true) do
			if self:MatchesFilter(dep.info, filter) then return true end
		end
	end
	return false
end

function StreamDebug:RenderFlowScopeTree(Iris, scopeEntry, rootsByScope, dbg, selectedIdx, filter)
	local scopeInfo = scopeEntry.info
	local roots = rootsByScope[scopeEntry.obj]
	if not roots then return end
	local scopeName = scopeInfo.displayName or scopeInfo.name or scopeInfo.source

	if filter ~= "" and not self:FlowScopeMatchesFilter(roots, dbg, filter) then
		return
	end

	Iris.PushId("fs" .. tostring(scopeInfo.index))
	Iris.Tree({ string.format("%s %s", richIcon("Scope"), scopeName) })

	local visited = {}
	for _, root in roots do
		self:RenderFlowNode(Iris, root, dbg, selectedIdx, filter, visited, 0)
	end

	Iris.End()
	Iris.PopId()
end

function StreamDebug:RenderFlowView(Iris, dbg, data, selectedIdx, filter)
	-- Leaked (same as scopes view)
	if #data.orphaned > 0 then
		Iris.PushConfig({ RichText = true })
		Iris.PushId("leaked_flow")
		Iris.Tree({ string.format(
			'%s <font color="#E84A4A">Leaked (%d)</font>',
			richIcon("Leaked"), #data.orphaned
			), nil, nil, true })
		Iris.Text({ "Objects whose scope was destroyed but were not cleaned up.", nil, Color3.fromRGB(255, 90, 90) })
		for _, entry in data.orphaned do
			if self:MatchesFilter(entry.info, filter) then
				self:RenderExplorerItem(Iris, entry, dbg, selectedIdx, true)
			end
		end
		Iris.End()
		Iris.PopId()
		Iris.PopConfig()
	end

	-- Group root Values by scope
	local rootsByScope = {}
	local scopeOrder = {}
	local unscopedRoots = {}

	for obj, info in dbg.objects do
		if info.type ~= "Value" then continue end
		local scope = info.scope
		if scope and dbg.objects[scope] then
			if not rootsByScope[scope] then
				rootsByScope[scope] = {}
				table.insert(scopeOrder, { obj = scope, info = dbg.objects[scope] })
			end
			table.insert(rootsByScope[scope], { obj = obj, info = info })
		else
			table.insert(unscopedRoots, { obj = obj, info = info })
		end
	end

	local function byIndex(a, b) return a.info.index < b.info.index end
	local itemSort = self:ByTypeAndName()
	table.sort(scopeOrder, byIndex)
	for _, list in rootsByScope do table.sort(list, itemSort) end
	table.sort(unscopedRoots, itemSort)

	-- Group scopes by category (mirroring Scopes view)
	local categorizedScopes = {}
	local flowCategoryOrder = {}
	local uncategorizedFlowScopes = {}

	for _, scopeEntry in scopeOrder do
		local cat = scopeEntry.info.category
		if cat then
			if not categorizedScopes[cat] then
				categorizedScopes[cat] = {}
				table.insert(flowCategoryOrder, cat)
			end
			table.insert(categorizedScopes[cat], scopeEntry)
		else
			table.insert(uncategorizedFlowScopes, scopeEntry)
		end
	end
	table.sort(flowCategoryOrder)

	Iris.PushConfig({ RichText = true })

	-- Categorized scope groups
	for _, cat in flowCategoryOrder do
		local catEntries = categorizedScopes[cat]

		if filter ~= "" then
			local anyVisible = false
			for _, scopeEntry in catEntries do
				local roots = rootsByScope[scopeEntry.obj]
				if roots and self:FlowScopeMatchesFilter(roots, dbg, filter) then
					anyVisible = true
					break
				end
			end
			if not anyVisible then continue end
		end

		Iris.PushId("fcat_" .. cat)
		Iris.Tree({ string.format("%s %s (%d)", richIcon("Category"), cat, #catEntries) })

		for _, scopeEntry in catEntries do
			self:RenderFlowScopeTree(Iris, scopeEntry, rootsByScope, dbg, selectedIdx, filter)
		end

		Iris.End()
		Iris.PopId()
	end

	-- Uncategorized scopes
	for _, scopeEntry in uncategorizedFlowScopes do
		self:RenderFlowScopeTree(Iris, scopeEntry, rootsByScope, dbg, selectedIdx, filter)
	end

	-- Unscoped roots
	if #unscopedRoots > 0 then
		Iris.PushId("flow_unscoped")
		Iris.Tree({ string.format("Unscoped (%d)", #unscopedRoots) })

		local visited = {}
		for _, root in unscopedRoots do
			self:RenderFlowNode(Iris, root, dbg, selectedIdx, filter, visited, 0)
		end

		Iris.End()
		Iris.PopId()
	end

	Iris.PopConfig()
end


-- Detail panel

function StreamDebug:UpdateInspectorHeader(windowWidget, Iris, info, obj)
	local windowRoot = windowWidget.Instance
	if not windowRoot then return end
	local windowButton = windowRoot:FindFirstChild("WindowButton")
	if not windowButton then return end
	local content = windowButton:FindFirstChild("Content")
	if not content then return end
	
	content.BackgroundTransparency = 0
	content.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	
	local cfg = Iris.Internal._config
	local headerBar = content:FindFirstChild("InspectorHeaderBar")

	if not headerBar then
		local iconSize = math.floor(cfg.TextSize * 0.9)

		headerBar = Instance.new("Frame")
		headerBar.Name = "InspectorHeaderBar"
		headerBar.Size = UDim2.new(1, 0, 0, cfg.TextSize + 2 * cfg.FramePadding.Y)
		headerBar.BackgroundColor3 = cfg.HeaderColor
		headerBar.BackgroundTransparency = cfg.HeaderTransparency
		headerBar.BorderSizePixel = 0
		headerBar.LayoutOrder = 1 -- between TitleBar (0) and WindowContainer (0xFFFF+)
		headerBar.ClipsDescendants = true

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, cfg.WindowPadding.X)
		pad.PaddingRight = UDim.new(0, cfg.WindowPadding.X)
		pad.Parent = headerBar

		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Padding = UDim.new(0, cfg.ItemInnerSpacing.X)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = headerBar

		-- Icon badge
		local icon = Instance.new("Frame")
		icon.Name = "Icon"
		icon.Size = UDim2.fromOffset(iconSize, iconSize)
		icon.BackgroundColor3 = ICON_COLORS.Value
		icon.BorderSizePixel = 0
		icon.LayoutOrder = 0

		local iconCorner = Instance.new("UICorner")
		iconCorner.CornerRadius = UDim.new(0, 3)
		iconCorner.Parent = icon

		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "IconLabel"
		iconLabel.Size = UDim2.fromScale(1, 1)
		iconLabel.BackgroundTransparency = 1
		iconLabel.BorderSizePixel = 0
		iconLabel.Text = "V"
		iconLabel.TextColor3 = Color3.new(1, 1, 1)
		iconLabel.TextSize = 8
		iconLabel.FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold)
		iconLabel.TextXAlignment = Enum.TextXAlignment.Center
		iconLabel.TextYAlignment = Enum.TextYAlignment.Center
		iconLabel.Parent = icon

		icon.Parent = headerBar

		-- Name label
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.fromOffset(0, 0)
		nameLabel.AutomaticSize = Enum.AutomaticSize.XY
		nameLabel.BackgroundTransparency = 1
		nameLabel.BorderSizePixel = 0
		nameLabel.Text = ""
		nameLabel.TextColor3 = cfg.TextColor
		nameLabel.TextTransparency = cfg.TextTransparency
		nameLabel.TextSize = cfg.TextSize
		nameLabel.FontFace = cfg.TextFont
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.LayoutOrder = 1
		nameLabel.Parent = headerBar

		-- Value label
		local valueLabel = Instance.new("TextLabel")
		valueLabel.Name = "ValueLabel"
		valueLabel.Size = UDim2.fromOffset(0, 0)
		valueLabel.AutomaticSize = Enum.AutomaticSize.XY
		valueLabel.BackgroundTransparency = 1
		valueLabel.BorderSizePixel = 0
		valueLabel.Text = ""
		valueLabel.TextColor3 = VALUE_TEXT_COLOR
		valueLabel.TextSize = cfg.TextSize
		valueLabel.FontFace = cfg.TextFont
		valueLabel.TextXAlignment = Enum.TextXAlignment.Left
		valueLabel.LayoutOrder = 2
		valueLabel.Parent = headerBar

		headerBar.Parent = content
	end

	-- Update content each frame
	if info and obj then
		headerBar.Visible = true
		headerBar.Icon.BackgroundColor3 = ICON_COLORS[info.type] or ICON_COLORS.Category
		headerBar.Icon.IconLabel.Text = ICON_LETTERS[info.type] or "?"
		headerBar.NameLabel.Text = self:FormatRef(info)
		local valStr = self:FormatValue(obj._value)
		if valStr ~= "" then
			headerBar.ValueLabel.Text = "= " .. valStr
			headerBar.ValueLabel.Visible = true
		else
			headerBar.ValueLabel.Visible = false
		end
	else
		headerBar.Visible = false
	end
end

function StreamDebug:RenderDetailReference(Iris, refEntry, selectedIdx)
	local info = refEntry.info
	local iconColor = ICON_COLORS[info.type] or ICON_COLORS.Category
	local ref = self:FormatRef(info)
	local valStr = self:FormatValue(refEntry.obj._value)

	Iris.PushId("ref_" .. tostring(info.index))
	Iris.SameLine({ 4, Enum.VerticalAlignment.Center })
	Iris.Text({ string.format("  %s ", ICON_LETTERS[info.type] or "?"), nil, iconColor })
	if Iris.SmallButton({ string.format("%s = %s", ref, valStr) }).clicked() then
		self:NavigateTo(selectedIdx, info.index)
	end
	Iris.End()
	Iris.PopId()
end

function StreamDebug:RenderDetails(Iris, dbg, selectedIdx, indexToEntry)
	local idx = selectedIdx:get()
	local entry = indexToEntry[idx]

	if not entry then
		Iris.Text({ "Click an item to inspect it.", nil, Color3.fromRGB(120, 120, 120) })
		return
	end

	local obj = entry.obj
	local info = entry.info

	if not dbg.objects[obj] then
		Iris.Text({ "Selected object was destroyed.", nil, Color3.fromRGB(255, 90, 90) })
		selectedIdx:set(0)
		return
	end
	
	-- Navigation
	-- Wrapped so its presence/absence doesn't shift IDs below
	Iris.PushId("nav")
	if #self._navStack > 0 then
		if Iris.SmallButton({ "← Back" }).clicked() then
			self:NavigateBack(selectedIdx)
		end
	end
	Iris.PopId()

	-- Current val
	
	Iris.PushId("value")
	if info.type ~= "Scope" then
		local fullVal = tostring(obj._value)
		if #fullVal > 80 then fullVal = fullVal:sub(1, 80) .. "…" end
		Iris.Text({ string.format("Value: %s", fullVal), nil, VALUE_TEXT_COLOR })
	end
	Iris.PopId()

	-- Time info 
	
	Iris.PushId("temporal")
	Iris.Text({ string.format("Age: %s", self:FormatAge(info.createdAt)) })
	if info.updateCount and info.updateCount > 0 then
		local updateLabel = string.format("Updates: %d", info.updateCount)
		if info.lastUpdateTime then
			updateLabel ..= string.format("  (last %s ago)", self:FormatAge(info.lastUpdateTime))
		end
		Iris.Text({ updateLabel })
	end
	Iris.PopId()

	-- Scope link
	
	Iris.PushId("scope_link")
	if info.scope then
		local scopeInfo = dbg.objects[info.scope]
		if scopeInfo then
			Iris.SameLine({ 0, Enum.VerticalAlignment.Center })
			Iris.Text({ "Scope: " })
			local scopeLabel = scopeInfo.displayName or scopeInfo.name or string.format("#%d", scopeInfo.index)
			if Iris.SmallButton({ scopeLabel }).clicked() then
				self:NavigateTo(selectedIdx, scopeInfo.index)
			end
			Iris.End()
		end
	end
	Iris.PopId()

	-- Computed only triggered
	
	Iris.PushId("triggered_by")
	if info.type == "Computed" and info.lastTriggeredBy then
		local triggerInfo = dbg.objects[info.lastTriggeredBy]
		if triggerInfo then
			Iris.SameLine({ 4, Enum.VerticalAlignment.Center })
			Iris.Text({ "Triggered by: " })
			local trigRef = self:FormatRef(triggerInfo)
			if Iris.SmallButton({ trigRef }).clicked() then
				self:NavigateTo(selectedIdx, triggerInfo.index)
			end
			Iris.End()
		end
	end
	Iris.PopId()

	-- Dependencies
	
	Iris.PushId("deps")
	if info.type == "Computed" and obj._listening then
		local deps = {}
		for dep in obj._listening do
			local depInfo = dbg.objects[dep]
			if depInfo then table.insert(deps, { obj = dep, info = depInfo }) end
		end
		table.sort(deps, function(a, b) return a.info.index < b.info.index end)

		if #deps > 0 then
			Iris.Tree({ string.format("Dependencies  (%d)", #deps), nil, nil, true })
			for _, depEntry in deps do
				self:RenderDetailReference(Iris, depEntry, selectedIdx)
			end
			Iris.End()
		end
	end
	Iris.PopId()

	-- Listeners
	
	Iris.PushId("listeners")
	if obj._listeners then
		local streamListeners = {}
		local callbackListeners = {}

		for key in obj._listeners do
			if typeof(key) == "table" then
				local keyInfo = dbg.objects[key]
				if keyInfo then table.insert(streamListeners, { obj = key, info = keyInfo }) end
			elseif type(key) == "number" then
				local cbInfo = dbg.callbacks and dbg.callbacks[key]
				table.insert(callbackListeners, {
					id = key,
					source = if cbInfo then string.format("%s:%d", cbInfo.source, cbInfo.line) else string.format("#%d", key),
				})
			end
		end
		table.sort(streamListeners, function(a, b) return a.info.index < b.info.index end)
		table.sort(callbackListeners, function(a, b) return a.id < b.id end)

		local totalListeners = #streamListeners + #callbackListeners
		if totalListeners > 0 then
			Iris.Tree({ string.format("Listeners  (%d)", totalListeners), nil, nil, true })
			for _, listEntry in streamListeners do
				self:RenderDetailReference(Iris, listEntry, selectedIdx)
			end
			for _, cbEntry in callbackListeners do
				Iris.Text({ string.format("  ƒ  Callback (%s)", cbEntry.source), nil, ICON_COLORS.Callback })
			end
			Iris.End()
		end
	end
	Iris.PopId()

	-- Scope contents
	
	Iris.PushId("contents")
	if info.type == "Scope" and obj._items then
		local scopedItems = {}
		for _, item in obj._items do
			local itemInfo = dbg.objects[item]
			if itemInfo then table.insert(scopedItems, { obj = item, info = itemInfo }) end
		end
		table.sort(scopedItems, function(a, b) return a.info.index < b.info.index end)

		if #scopedItems > 0 then
			Iris.Tree({ string.format("Contents  (%d)", #scopedItems), nil, nil, true })
			for _, itemEntry in scopedItems do
				self:RenderDetailReference(Iris, itemEntry, selectedIdx)
			end
			Iris.End()
		end
	end
	Iris.PopId()

	-- History
	
	Iris.PushId("history")
	local log = dbg.log
	if log and #log > 0 then
		local selectedIndex = info.index
		local filtered = {}
		for i = #log, 1, -1 do
			local logEntry = log[i]
			if logEntry.index == selectedIndex then
				table.insert(filtered, logEntry)
				if #filtered >= 15 then break end
			end
		end

		if #filtered > 0 then
			Iris.Tree({ string.format("History  (%d)", #filtered), nil, nil, true })
			for _, logEntry in filtered do
				local age = self:FormatAge(logEntry.time)
				local line = string.format("%s ago:  %s → %s", age, logEntry.oldStr, logEntry.newStr)
				if logEntry.triggeredByRef then
					line ..= string.format("  (from %s)", logEntry.triggeredByRef)
				end
				Iris.Text({ line, nil, Color3.fromRGB(160, 160, 160) })
			end
			Iris.End()
		end
	end
	Iris.PopId()
end

function StreamDebug:RenderLog(Iris, dbg)
	local log = dbg.log
	if not log or #log == 0 then
		Iris.Text({ "No updates recorded yet.", nil, Color3.fromRGB(120, 120, 120) })
		return
	end

	local count = math.min(#log, 30)
	for i = #log, #log - count + 1, -1 do
		local entry = log[i]
		if not entry then continue end
		local age = self:FormatAge(entry.time)
		local icon = if entry.objType == "Value" then "V" else "C"
		local iconColor = ICON_COLORS[entry.objType] or ICON_COLORS.Category

		local line = string.format("%s  %s:  %s → %s", age, entry.ref, entry.oldStr, entry.newStr)
		if entry.objType == "Computed" and entry.triggeredByRef then
			line ..= string.format("  (from %s)", entry.triggeredByRef)
		end
		Iris.Text({ line, nil, iconColor })
	end
end

-- Iris render

function StreamDebug:Render(Iris,dbg)
	-- Guard: don't render content if visibility state was cleared
	if not self.Visible or not self.Visible:get() then
		return
	end

	local scopes, scopeItems, unscoped, orphaned = {}, {}, {}, {}
	local indexToEntry = {}
	local valCt, compCt, scopeCt = 0, 0, 0

	if dbg then
		for obj, info in dbg.objects do
			indexToEntry[info.index] = { obj = obj, info = info }
			if info.type == "Scope" then
				scopeCt += 1
				table.insert(scopes, { obj = obj, info = info })
				if not scopeItems[obj] then scopeItems[obj] = {} end
			elseif info.type == "Value" then
				valCt += 1
			elseif info.type == "Computed" then
				compCt += 1
			end
		end

		for obj, info in dbg.objects do
			if info.type == "Scope" then continue end
			local scope = info.scope
			if scope and scopeItems[scope] then
				table.insert(scopeItems[scope], { obj = obj, info = info })
			elseif scope and not dbg.objects[scope] then
				table.insert(orphaned, { obj = obj, info = info })
			else
				table.insert(unscoped, { obj = obj, info = info })
			end
		end

		local function byIndex(a, b) return a.info.index < b.info.index end
		local itemSort = self:ByTypeAndName()
		table.sort(scopes, byIndex)
		table.sort(unscoped, itemSort)
		table.sort(orphaned, itemSort)
		for _, items in scopeItems do table.sort(items, itemSort) end
	end

	local categorized, categoryOrder, uncategorizedScopes = {}, {}, {}
	for _, entry in scopes do
		local cat = entry.info.category
		if cat then
			if not categorized[cat] then
				categorized[cat] = {}
				table.insert(categoryOrder, cat)
			end
			table.insert(categorized[cat], entry)
		else
			table.insert(uncategorizedScopes, entry)
		end
	end
	table.sort(categoryOrder)

	local data = {
		scopes = scopes,
		scopeItems = scopeItems,
		unscoped = unscoped,
		orphaned = orphaned,
		categorized = categorized,
		categoryOrder = categoryOrder,
		uncategorizedScopes = uncategorizedScopes,
	}

	-- Shared states (created inside Render so Iris IDs are stable per-cycle)
	local viewMode = Iris.State("Flow")
	local filterState = Iris.State("")
	local selectedIdx = Iris.State(0)

	-- Explorer
	
	Iris.Window({ "StreamDebug Explorer" }, {
		position = self.Position,
		isOpened = self.Visible,
		size = self.Size,
	})

	if not dbg then
		Iris.Text({ "Stream debug tracking unavailable." })
		Iris.End()

		Iris.Window({ "StreamDebug Inspector", nil, nil, nil, true }, {
			position = self.InspectorPos,
			isOpened = self.Visible,
			size = self.InspectorSize,
		})
		Iris.End()
		return
	end

	-- Stats bar
	local total = valCt + compCt + scopeCt
	local statsLabel = string.format("%d Values  |  %d Computed  |  %d Scopes  |  %d Total", valCt, compCt, scopeCt, total)
	if #orphaned > 0 then
		statsLabel ..= string.format("  |  ⚠ %d Leaked", #orphaned)
	end
	Iris.SeparatorText({ statsLabel })

	-- View toggle + search
	Iris.SameLine()
	local isScopes = viewMode:get() == "Scopes"
	if Iris.SmallButton({ if isScopes then "[Scopes]" else "Scopes" }).clicked() then
		viewMode:set("Scopes")
	end
	if Iris.SmallButton({ if isScopes then "Flow" else "[Flow]" }).clicked() then
		viewMode:set("Flow")
	end
	Iris.End()

	local filterWidget = Iris.InputText({ "", "Search…" }, { text = filterState })
	local filter = ""
	local inputField = filterWidget.Instance and filterWidget.Instance:FindFirstChild("InputField")
	if inputField then
		filter = inputField.Text or ""
	end

	-- Tree content
	if viewMode:get() == "Flow" then
		self:RenderFlowView(Iris, dbg, data, selectedIdx, filter)
	else
		self:RenderScopesView(Iris, dbg, data, selectedIdx, filter)
	end

	Iris.End() -- Explorer Window

	
	-- Inspector
	
	local selIdx = selectedIdx:get()
	local selEntry = indexToEntry[selIdx]
	local selValid = selEntry and dbg.objects[selEntry.obj]
	
	local inspectorWindow = Iris.Window({
		"StreamDebug Inspector",
		nil,          -- NoTitleBar
		nil,          -- NoBackground
		nil,          -- NoCollapse
		true,         -- NoClose
	}, {
		position = self.InspectorPos,
		isOpened = self.Visible,
		size = self.InspectorSize,
	})

	-- Non-scrolling header bar (injected into Content, above the ScrollingFrame)
	if selValid then
		self:UpdateInspectorHeader(inspectorWindow, Iris, selEntry.info, selEntry.obj)
	else
		self:UpdateInspectorHeader(inspectorWindow, Iris, nil, nil)
	end

	-- Tab bar: rendered FIRST so Iris IDs are stable regardless of selection
	local inspectorTab = Iris.State("Details")
	Iris.SameLine()
	if Iris.SmallButton({ if inspectorTab:get() == "Details" then "[Details]" else "Details" }).clicked() then
		inspectorTab:set("Details")
	end
	if Iris.SmallButton({ if inspectorTab:get() == "Log" then "[Log]" else "Log" }).clicked() then
		inspectorTab:set("Log")
	end
	Iris.End()

	-- Tab content
	if inspectorTab:get() == "Log" then
		Iris.PushId("log_content")
		self:RenderLog(Iris, dbg)
		Iris.PopId()
	else
		Iris.PushId("detail_content")
		self:RenderDetails(Iris, dbg, selectedIdx, indexToEntry)
		Iris.PopId()
	end

	Iris.End() -- Inspector Window
end

return StreamDebug
