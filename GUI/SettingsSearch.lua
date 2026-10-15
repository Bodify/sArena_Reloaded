-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

local L = sArenaMixin.L
local AceGUI = LibStub("AceGUI-3.0", true)
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

local maxResults = 40

local query = ""
local previousTab
local jumpSource

local searchableTypes = {
    toggle = true,
    range = true,
    select = true,
    multiselect = true,
    color = true,
    input = true,
    execute = true,
    keybinding = true,
}

local methodMembers = {
    get = true,
    set = true,
    func = true,
    validate = true,
    confirm = true,
    disabled = true,
    hidden = true,
    values = true,
    sorting = true,
    imageCoords = true,
}

local callableMembers = {
    "name", "desc", "get", "set", "func", "validate", "confirm", "disabled",
    "values", "sorting", "image", "imageCoords", "icon", "usage",
}
local inheritedMembers = { "get", "set", "func", "validate", "confirm", "disabled", "hidden" }

local function MakeInfo(source, ctx)
    local info = {}
    if source then
        for k, v in pairs(source) do
            if type(k) ~= "number" then
                info[k] = v
            end
        end
    end
    for i = 1, #ctx.path do
        info[i] = ctx.path[i]
    end
    info[0] = "sArena"
    info.appName = "sArena"
    info.options = ctx.options
    info.option = ctx.option
    info.arg = ctx.option.arg
    info.handler = ctx.handler
    info.type = ctx.option.type
    return info
end

local function Wrap(member, key, ctx)
    if type(member) == "function" then
        return function(info, ...)
            return member(MakeInfo(info, ctx), ...)
        end
    elseif type(member) == "string" and methodMembers[key] then
        return function(info, ...)
            local handler = ctx.handler
            return handler[member](handler, MakeInfo(info, ctx), ...)
        end
    end
    return member
end

local function Eval(member, key, ctx)
    local wrapped = Wrap(member, key, ctx)
    if wrapped == member then
        return member
    end
    return wrapped()
end

local function IsNodeHidden(node, ctx, inheritedHidden)
    local hidden = node.dialogHidden
    if hidden == nil then hidden = node.guiHidden end
    if hidden ~= nil then
        return hidden
    end
    local member = node.hidden
    if member == nil then member = inheritedHidden end
    return Eval(member, "hidden", ctx)
end

local function CopyOption(option, ctx, inherited, ancestors)
    local copy = {}
    for k, v in pairs(option) do
        copy[k] = v
    end
    for _, key in ipairs(inheritedMembers) do
        if copy[key] == nil then
            copy[key] = inherited[key]
        end
    end
    for _, key in ipairs(callableMembers) do
        copy[key] = Wrap(copy[key], key, ctx)
    end

    local inheritedHidden = inherited.hidden
    copy.dialogHidden = nil
    copy.guiHidden = nil
    copy.hidden = function()
        for _, ancestor in ipairs(ancestors) do
            if IsNodeHidden(ancestor.node, ancestor.ctx, ancestor.inheritedHidden) then
                return true
            end
        end
        return IsNodeHidden(option, ctx, inheritedHidden)
    end

    return copy
end

local function CleanText(text)
    if type(text) ~= "string" then
        return ""
    end
    return (text:gsub("|T.-|t", ""):gsub("|A.-|a", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|n", " "):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function SortedKeys(args, handler, options, path)
    local keys, orders, names = {}, {}, {}
    for k, v in pairs(args) do
        keys[#keys + 1] = k
        local childCtx = { path = path, option = v, handler = v.handler or handler, options = options }
        path[#path + 1] = k
        local order = Eval(v.order, "order", childCtx)
        orders[k] = type(order) == "number" and order or 100
        names[k] = CleanText(Eval(v.name, "name", childCtx)):upper()
        path[#path] = nil
    end
    table.sort(keys, function(a, b)
        local oa, ob = orders[a], orders[b]
        if oa == ob then
            if names[a] == names[b] then
                return tostring(a) < tostring(b)
            end
            return names[a] < names[b]
        end
        if (oa < 0) ~= (ob < 0) then
            return ob < 0
        end
        return oa < ob
    end)
    return keys
end

local synonymGroups = {
    { "size", "scale", "sizing" },
}

local synonyms = {}
for _, group in ipairs(synonymGroups) do
    for _, word in ipairs(group) do
        synonyms[word] = group
    end
end

local function WordForms(word)
    local forms = { word }
    if #word > 3 and word:sub(-1) == "s" then
        forms[#forms + 1] = word:sub(1, -2)
    end
    for i = 1, #forms do
        local group = synonyms[forms[i]]
        if group then
            for _, alt in ipairs(group) do
                forms[#forms + 1] = alt
            end
        end
    end
    return forms
end

local function HasWord(text, forms)
    for _, form in ipairs(forms) do
        if text:find(form, 1, true) then
            return true
        end
    end
    return false
end

local extraTerms = {
    forceEnglishGUI = "force english gui",
}

local function Matches(key, option, ctx, words, titles)
    local text = (CleanText(Eval(option.name, "name", ctx)) .. " " .. CleanText(Eval(option.desc, "desc", ctx))):lower()
    if extraTerms[key] then
        text = text .. " " .. extraTerms[key]
    end
    local groupText = (titles[#titles] or ""):lower()
    local pathText = table.concat(titles, " "):lower()
    local anchored = false
    for _, forms in ipairs(words) do
        if HasWord(text, forms) or HasWord(groupText, forms) then
            anchored = true
        elseif not HasWord(pathText, forms) then
            return false
        end
    end
    return anchored
end

local function CopyPath(path)
    local copy = {}
    for i = 1, #path do
        copy[i] = path[i]
    end
    return copy
end

local function IsInline(node)
    if node.dialogInline ~= nil then return node.dialogInline end
    if node.guiInline ~= nil then return node.guiInline end
    return node.inline
end

local function GetJumpTarget(ancestors)
    local selectPath, inlineTitles = {}, {}
    for _, ancestor in ipairs(ancestors) do
        if IsInline(ancestor.node) then
            local name = Eval(ancestor.node.name, "name", ancestor.ctx)
            if type(name) == "string" and name ~= "" then
                inlineTitles[#inlineTitles + 1] = name
            end
        else
            selectPath[#selectPath + 1] = ancestor.ctx.path[#ancestor.ctx.path]
            inlineTitles = {}
        end
    end
    return selectPath, inlineTitles
end

local function Walk(group, state, path, inherited, handler, ancestors, titles)
    for _, key in ipairs(SortedKeys(group.args, handler, state.options, path)) do
        local option = group.args[key]
        path[#path + 1] = key
        local nodeHandler = option.handler or handler
        local ctx = { path = CopyPath(path), option = option, handler = nodeHandler, options = state.options }

        if option.type == "group" then
            if not IsNodeHidden(option, ctx, inherited.hidden) and option.args then
                local childInherited = {}
                for _, member in ipairs(inheritedMembers) do
                    if option[member] ~= nil then
                        childInherited[member] = option[member]
                    else
                        childInherited[member] = inherited[member]
                    end
                end
                local childAncestors = { unpack(ancestors) }
                childAncestors[#childAncestors + 1] = { node = option, ctx = ctx, inheritedHidden = inherited.hidden }
                local childTitles = { unpack(titles) }
                local title = CleanText(Eval(option.name, "name", ctx))
                if title ~= "" then
                    childTitles[#childTitles + 1] = title
                end
                Walk(option, state, path, childInherited, nodeHandler, childAncestors, childTitles)
            end
        elseif searchableTypes[option.type] and Matches(key, option, ctx, state.words, titles) and not IsNodeHidden(option, ctx, inherited.hidden) then
            state.total = state.total + 1
            if state.total <= maxResults then
                local title = titles[1] or ""
                if #titles > 1 then
                    title = title .. ": " .. table.concat(titles, " > ", 2)
                end
                local section = state.sections[title]
                if not section then
                    state.sectionCount = state.sectionCount + 1
                    section = {
                        order = state.sectionCount,
                        name = title,
                        type = "group",
                        inline = true,
                        args = {},
                    }
                    state.sections[title] = section
                    state.args["section" .. state.sectionCount] = section
                    local selectPath, inlineTitles = GetJumpTarget(ancestors)
                    section.args.jump = {
                        order = 0,
                        name = "|A:transfer-log-button-up:15:16|a " .. L["Search_JumpTo"] .. " |A:arrow-long:19:25|a",
                        type = "execute",
                        dialogControl = "sArena_SearchJump",
                        validate = false,
                        func = function() sArenaMixin:JumpToSetting(selectPath, inlineTitles) end,
                    }
                end
                local copy = CopyOption(option, ctx, inherited, ancestors)
                copy.order = state.total
                section.args["option" .. state.total] = copy
            end
        end

        path[#path] = nil
    end
end

function sArenaMixin:UpdateSettingsSearch()
    local options = self.optionsTable
    local searchGroup = options and options.args.searchGroup
    if not searchGroup then return end

    local args = {}
    searchGroup.args = args
    if query == "" then return end

    local words = {}
    for word in query:lower():gmatch("%S+") do
        words[#words + 1] = WordForms(word)
    end

    local state = {
        options = options,
        words = words,
        args = args,
        sections = {},
        sectionCount = 0,
        total = 0,
    }
    local inherited = {}
    for _, member in ipairs(inheritedMembers) do
        inherited[member] = options[member]
    end

    local path = {}
    for _, key in ipairs(SortedKeys(options.args, options.handler, options, path)) do
        local tab = options.args[key]
        if key ~= "searchGroup" and tab.type == "group" and tab.args then
            local tabWrapper = { type = "group", args = { [key] = tab } }
            Walk(tabWrapper, state, path, inherited, options.handler, {}, {})
        end
    end

    if state.total == 0 then
        args.noResults = {
            order = 1,
            type = "description",
            name = L["Search_NoResults"],
            fontSize = "medium",
        }
    elseif state.total > maxResults then
        args.capped = {
            order = 0,
            type = "description",
            name = "|A:shop-games-magnifyingglass:20:20|a |cffff8000" .. L["Search_Results_Capped"]:format(maxResults, state.total) .. "|r\n ",
            fontSize = "large",
        }
    end
end

local function FindTabGroup(widget)
    local parent = type(widget) == "table" and widget.parent
    if not (parent and parent.children) then return end
    for _, child in ipairs(parent.children) do
        if child.type == "TabGroup" and child.tablist then
            return child
        end
    end
end

local function RefreshTabs(tabGroup, searching, wasSearching)
    if searching ~= wasSearching then
        local tabs = {}
        for _, entry in ipairs(tabGroup.tablist) do
            if entry.value ~= "searchGroup" then
                tabs[#tabs + 1] = entry
            end
        end
        if searching then
            tabs[#tabs + 1] = { value = "searchGroup", text = sArenaMixin.optionsTable.args.searchGroup.name }
        end
        tabGroup:SetTabs(tabs)
    end
    tabGroup:SelectTab(searching and "searchGroup" or previousTab or "layoutSettingsGroup")
end

function sArenaMixin:SetSettingsSearch(text, source)
    text = text or ""
    if text:match("^%s*$") then
        text = ""
    end
    local wasSearching = query ~= ""
    query = text
    local searching = query ~= ""

    local status = AceConfigDialog:GetStatusTable("sArena")
    status.groups = status.groups or {}

    if searching and not wasSearching then
        local selected = status.groups.selected
        previousTab = (selected and selected ~= "searchGroup") and selected or "layoutSettingsGroup"
    end

    local tabGroup = FindTabGroup(source)
    if tabGroup then
        self:UpdateSettingsSearch()
        RefreshTabs(tabGroup, searching, wasSearching)
    elseif searching and not wasSearching then
        AceConfigDialog:SelectGroup("sArena", "searchGroup")
    elseif wasSearching and not searching then
        AceConfigDialog:SelectGroup("sArena", previousTab or "layoutSettingsGroup")
    else
        AceConfigRegistry:NotifyChange("sArena")
    end
end

local function FindInlineGroup(widget, titles, index)
    for _, child in ipairs(widget.children or {}) do
        if child.type == "InlineGroup" and child.titletext and child.titletext:GetText() == titles[index] then
            if index == #titles then
                return child
            end
            local found = FindInlineGroup(child, titles, index + 1)
            if found then
                return found
            end
        else
            local found = FindInlineGroup(child, titles, index)
            if found then
                return found
            end
        end
    end
end

local function ScrollToWidget(target)
    local scroll = target.parent
    while scroll and scroll.type ~= "ScrollFrame" do
        scroll = scroll.parent
    end
    if not scroll then return true end

    local contentTop, targetTop = scroll.content:GetTop(), target.frame:GetTop()
    if not (contentTop and targetTop) then return false end

    local range = scroll.content:GetHeight() - scroll.scrollframe:GetHeight()
    if range > 0 and scroll.scrollBarShown then
        local value = math.min(1000, math.max(0, (contentTop - targetTop) / range * 1000))
        scroll.scrollbar:SetValue(value)
    end
    return true
end

local function FlashTitle(target)
    local title = target.titletext
    title:SetTextColor(1, 1, 1)
    C_Timer.After(1.5, function()
        title:SetTextColor(1, 0.82, 0)
    end)
end

function sArenaMixin:JumpToSetting(selectPath, inlineTitles)
    local root = jumpSource
    while root and root.parent do
        root = root.parent
    end
    jumpSource = nil

    AceConfigDialog:SelectGroup("sArena", unpack(selectPath))
    if not root or #inlineTitles == 0 then return end

    local tries, found = 0, nil
    local function Try()
        tries = tries + 1
        found = FindInlineGroup(root, inlineTitles, 1)
        if found and found.frame:IsVisible() and ScrollToWidget(found) then
            FlashTitle(found)
        elseif tries < 20 then
            C_Timer.After(0, Try)
        end
    end
    C_Timer.After(0, Try)
end

function sArenaMixin:GetSettingsSearch()
    return query
end

AceConfigRegistry.RegisterCallback(sArenaMixin, "ConfigTableChange", function(_, appName)
    if appName == "sArena" then
        sArenaMixin:UpdateSettingsSearch()
    end
end)

function sArenaMixin:AddSettingsSearchOptions()
    local args = self.optionsTable and self.optionsTable.args
    if not (args and args.layoutSettingsGroup) then return end

    args.settingsSearch = {
        order = 4,
        name = "",
        type = "input",
        dialogControl = "sArena_SearchBox",
        width = 1.5,
        validate = false,
        get = function() return query end,
        set = function(info, val) info.handler:SetSettingsSearch(val) end,
    }
    args.searchGroup = {
        order = 1000,
        name = "|TInterface\\Common\\UI-Searchbox-Icon:13:13|t " .. L["Search"],
        type = "group",
        hidden = function() return query == "" end,
        args = {},
    }
end

local function SearchBoxConstructor()
    local widget = AceGUI:Create("EditBox")
    if not widget then return end
    widget.type = "sArena_SearchBox"

    local editbox = widget.editbox

    local icon = editbox:CreateTexture(nil, "OVERLAY")
    icon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    icon:SetSize(14, 14)
    icon:SetPoint("LEFT", 0, -1)
    icon:SetVertexColor(0.6, 0.6, 0.6)

    local placeholder = editbox:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    placeholder:SetPoint("LEFT", 18, 0)
    placeholder:SetPoint("RIGHT", -4, 0)
    placeholder:SetJustifyH("LEFT")
    placeholder:SetText(L["Search_Placeholder"])

    local function UpdatePlaceholder()
        local empty = editbox:GetText() == ""
        placeholder:SetShown(empty)
        if empty then
            icon:SetVertexColor(0.6, 0.6, 0.6)
        else
            icon:SetVertexColor(1, 1, 1)
        end
    end

    local setTextInsets = editbox.SetTextInsets
    editbox.SetTextInsets = function(self, _, right, top, bottom)
        setTextInsets(self, 18, right, top, bottom)
    end
    editbox:SetTextInsets(0, 0, 3, 3)

    editbox:HookScript("OnTextChanged", function(self, userInput)
        UpdatePlaceholder()
        if userInput then
            _G.sArena:SetSettingsSearch(self:GetText(), widget)
        end
    end)

    local origOnAcquire = widget.OnAcquire
    widget.OnAcquire = function(self)
        origOnAcquire(self)
        self:DisableButton(true)
    end
    widget:DisableButton(true)

    local origSetText = widget.SetText
    widget.SetText = function(self, text)
        origSetText(self, text)
        UpdatePlaceholder()
    end

    return widget
end

AceGUI:RegisterWidgetType("sArena_SearchBox", SearchBoxConstructor, 1)

local jumpMethods = {
    OnAcquire = function(self)
        self.frame:SetSize(0, 1)
        self:SetDisabled(false)
    end,
    OnRelease = function(self)
        self.button:ClearAllPoints()
        self.button:Hide()
    end,
    SetParent = function(self, parent)
        local frame = self.frame
        frame:SetParent(nil)
        frame:SetParent(parent.content)
        self.parent = parent

        local button, title = self.button, parent.titletext
        button:ClearAllPoints()
        if title then
            button:SetPoint("LEFT", title, "LEFT", title:GetStringWidth() + 8, 0)
            button:Show()
        else
            button:Hide()
        end
    end,
    SetWidth = function(self)
        self.frame:SetWidth(0)
    end,
    SetText = function(self, text)
        self.text:SetText(text)
        self.button:SetSize(self.text:GetStringWidth() + 4, 18)
    end,
    SetDisabled = function(self, disabled)
        self.disabled = disabled
        self.button:SetEnabled(not disabled)
    end,
}

local function JumpButtonConstructor()
    local frame = CreateFrame("Frame")
    frame:SetSize(0, 1)

    local button = CreateFrame("Button", nil, frame)
    button:SetHeight(18)
    local text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", 2, 0)
    text:SetTextColor(0.1, 1, 0.1)

    local widget = {
        type = "sArena_SearchJump",
        frame = frame,
        button = button,
        text = text,
    }
    for name, method in pairs(jumpMethods) do
        widget[name] = method
    end

    button:SetScript("OnEnter", function()
        text:SetTextColor(1, 1, 1)
        GameTooltip:SetOwner(button, "ANCHOR_TOP")
        GameTooltip:AddLine(L["Search_JumpTo_Tooltip"], 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        text:SetTextColor(0.1, 1, 0.1)
        GameTooltip:Hide()
    end)
    button:SetScript("OnClick", function()
        jumpSource = widget
        widget:Fire("OnClick")
    end)

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType("sArena_SearchJump", JumpButtonConstructor, 1)
