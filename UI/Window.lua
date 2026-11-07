-- Gilded window. /wcc and /worldcolor open it.

WorldColorCode = WorldColorCode or {}

local WCC = WorldColorCode

local FONT = "Fonts\\FRIZQT__.TTF"
local WIDTH = 680
local HEIGHT = 520
local TITLE_H = 20
local FOOTER_H = 28
local LEFT_W = 210
local PAD = 8
local ROW_H = 24
local ZONE_H = 22
local HEAD_H = 18

local GILDED = {
    bg = { 0.039, 0.039, 0.039, 0.96 },
    headerBg = { 0.078, 0.078, 0.078, 1 },
    here = { 0.280, 0.180, 0.050, 1 },
    rowHover = { 0.110, 0.090, 0.055, 1 },
    border = { 0.220, 0.220, 0.220, 1 },
    accent = { 1.000, 0.690, 0.125, 1 },
    textPrimary = { 0.910, 0.910, 0.910, 1 },
    textSecondary = { 0.560, 0.560, 0.560, 1 },
    textDim = { 0.320, 0.320, 0.320, 1 },
    inputBg = { 0.027, 0.027, 0.027, 1 },
}

local PATH_ARROW_ATLAS = "CovenantSanctum-Renown-DoubleArrow-Depressed"
local pathArrowBake

local state = {
    mapID = nil,
    nearby = false,
    showAll = false,
}

local window
local news

local function ApplyColor(tex, color)
    tex:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
end

local function ApplyText(fs, color)
    fs:SetTextColor(color[1], color[2], color[3], color[4] or 1)
end

local function Face(fs, size)
    fs:SetFont(FONT, size, "")
    fs:SetShadowOffset(0, 0)
    fs:SetShadowColor(0, 0, 0, 0)
end

local function Edge(parent, side, color, thickness)
    local tex = parent:CreateTexture(nil, "BORDER")
    ApplyColor(tex, color)
    thickness = thickness or 1
    if side == "LEFT" then
        tex:SetPoint("TOPLEFT")
        tex:SetPoint("BOTTOMLEFT")
        tex:SetWidth(thickness)
    elseif side == "RIGHT" then
        tex:SetPoint("TOPRIGHT")
        tex:SetPoint("BOTTOMRIGHT")
        tex:SetWidth(thickness)
    elseif side == "TOP" then
        tex:SetPoint("TOPLEFT")
        tex:SetPoint("TOPRIGHT")
        tex:SetHeight(thickness)
    else
        tex:SetPoint("BOTTOMLEFT")
        tex:SetPoint("BOTTOMRIGHT")
        tex:SetHeight(thickness)
    end
    return tex
end

local function Box(parent, color)
    Edge(parent, "LEFT", color, 1)
    Edge(parent, "RIGHT", color, 1)
    Edge(parent, "TOP", color, 1)
    Edge(parent, "BOTTOM", color, 1)
end

local function bakedPathArrow()
    if pathArrowBake then return pathArrowBake end
    local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(PATH_ARROW_ATLAS)
    if not info or not info.file or info.leftTexCoord == nil or info.rightTexCoord == nil then
        return nil
    end
    local dim = 2048
    local function q(v)
        return math.floor((tonumber(v) or 0) * dim + 0.5)
    end
    local aw = tonumber(info.width) or 1
    local ah = tonumber(info.height) or 1
    if ah < 1 then ah = 1 end
    pathArrowBake = {
        file = info.file,
        dim = dim,
        l = q(info.rightTexCoord),
        r = q(info.leftTexCoord),
        t = q(info.topTexCoord),
        b = q(info.bottomTexCoord),
        aspect = aw / ah,
    }
    return pathArrowBake
end

function WCC.RightChevronMarkup(h)
    h = tonumber(h) or 12
    local bake = bakedPathArrow()
    if not bake then return ">" end
    local w = math.max(8, math.floor(h * bake.aspect + 0.5))
    return string.format(
        "|T%s:%d:%d:0:0:%d:%d:%d:%d:%d:%d|t",
        bake.file, h, w, bake.dim, bake.dim, bake.l, bake.r, bake.t, bake.b
    )
end

function WCC.WithPathArrows(text, h)
    if type(text) ~= "string" or not text:find("→", 1, true) then
        return text
    end
    return (text:gsub("→", WCC.RightChevronMarkup(h or 12)))
end

local function AddonVersion()
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        local ok, version = pcall(C_AddOns.GetAddOnMetadata, "WorldColorCode", "Version")
        if ok and type(version) == "string" and version ~= "" then
            return version
        end
    end
    local notes = WCC.WHATS_NEW
    local first = notes and notes[1]
    return (first and first.version) or ""
end

local function Trim(text)
    if type(text) ~= "string" then return "" end
    return (text:match("^%s*(.-)%s*$")) or ""
end

local TRACK_W = 8
local THUMB_MIN = 28

local function ContentWidth(scroll, fallback)
    local width = scroll:GetWidth() or 0
    if width < 40 then
        width = fallback or width
    end
    return math.max(20, width - TRACK_W - 2)
end

local function Wheel(scroll, delta)
    local child = scroll:GetScrollChild()
    local maxScroll = 0
    if child then
        maxScroll = math.max(0, (child:GetHeight() or 0) - scroll:GetHeight())
    end
    local nextScroll = scroll:GetVerticalScroll() - delta * 36
    if nextScroll < 0 then nextScroll = 0 end
    if nextScroll > maxScroll then nextScroll = maxScroll end
    scroll:SetVerticalScroll(nextScroll)
end

local function MakeScroll(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", Wheel)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(20, 20)
    scroll:SetScrollChild(child)
    scroll.child = child
    scroll:SetScript("OnSizeChanged", function(self)
        child:SetWidth(ContentWidth(self))
    end)

    local track = CreateFrame("Frame", nil, parent)
    track:SetWidth(TRACK_W)
    track:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", 0, 0)
    track:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 0, 0)
    track:SetFrameLevel((scroll:GetFrameLevel() or 1) + 5)
    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints()
    ApplyColor(trackBg, GILDED.headerBg)
    Box(track, GILDED.border)

    local thumb = CreateFrame("Button", nil, track)
    thumb:SetWidth(TRACK_W - 2)
    thumb:SetPoint("TOP", track, "TOP", 0, -1)
    local thumbTex = thumb:CreateTexture(nil, "ARTWORK")
    thumbTex:SetAllPoints()
    ApplyColor(thumbTex, GILDED.accent)

    local updating = false
    local function UpdateThumb()
        if updating then return end
        updating = true
        local frameH = scroll:GetHeight() or 0
        local contentH = child:GetHeight() or 0
        local trackH = track:GetHeight() or 0
        local maxScroll = math.max(0, contentH - frameH)
        local cur = scroll:GetVerticalScroll() or 0
        if cur < 0 or cur > maxScroll then
            scroll:SetVerticalScroll(math.max(0, math.min(maxScroll, cur)))
            cur = scroll:GetVerticalScroll() or 0
        end
        if maxScroll <= 0.5 or trackH <= THUMB_MIN then
            thumb:Hide()
            updating = false
            return
        end
        thumb:Show()
        local thumbH = math.max(THUMB_MIN, trackH * (frameH / math.max(contentH, 1)))
        if thumbH > trackH - 2 then thumbH = trackH - 2 end
        thumb:SetHeight(thumbH)
        local scrollPct = maxScroll > 0 and math.max(0, math.min(1, cur / maxScroll)) or 0
        local maxOffset = math.max(0, trackH - thumbH - 2)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", track, "TOP", 0, -(1 + scrollPct * maxOffset))
        updating = false
    end

    local dragStartY, dragStartScroll
    thumb:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" then return end
        dragStartY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        dragStartScroll = scroll:GetVerticalScroll()
        thumb:SetScript("OnUpdate", function()
            local curY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
            local delta = dragStartY - curY
            local frameH = scroll:GetHeight()
            local contentH = child:GetHeight() or 0
            local trackH = track:GetHeight()
            local thumbH = thumb:GetHeight()
            local span = trackH - thumbH
            local ratio = span > 0 and (contentH - frameH) / span or 0
            local new = math.max(0, math.min(contentH - frameH, dragStartScroll + delta * ratio))
            scroll:SetVerticalScroll(new)
        end)
    end)
    thumb:SetScript("OnMouseUp", function()
        thumb:SetScript("OnUpdate", nil)
    end)

    track:EnableMouse(true)
    track:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" then return end
        local curY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local clickOffset = (track:GetTop() or 0) - curY
        local frameH = scroll:GetHeight()
        local contentH = child:GetHeight() or 0
        local trackH = track:GetHeight()
        local thumbH = thumb:IsShown() and thumb:GetHeight() or THUMB_MIN
        local span = trackH - thumbH
        local ratio = span > 0 and (contentH - frameH) / span or 0
        local new = math.max(0, math.min(math.max(0, contentH - frameH), (clickOffset - thumbH / 2) * ratio))
        scroll:SetVerticalScroll(new)
    end)

    scroll:HookScript("OnVerticalScroll", UpdateThumb)
    scroll:HookScript("OnScrollRangeChanged", UpdateThumb)
    scroll:HookScript("OnSizeChanged", UpdateThumb)
    scroll.UpdateScrollBar = UpdateThumb
    UpdateThumb()
    return scroll
end

local function Acquire(pool, parent, factory)
    pool.used = (pool.used or 0) + 1
    local row = pool[pool.used]
    if not row then
        row = factory(parent)
        pool[pool.used] = row
    end
    row:Show()
    return row
end

local function Release(pool)
    for i = 1, #pool do
        pool[i]:Hide()
    end
    pool.used = 0
end

local function PickColor(r, g, b, onChange, onCancel)
    local function read()
        if ColorPickerFrame.GetColorRGB then
            return ColorPickerFrame:GetColorRGB()
        end
        return r, g, b
    end
    local function apply()
        local nr, ng, nb = read()
        onChange(nr, ng, nb)
    end
    local function cancel(previous)
        if onCancel then
            onCancel()
            return
        end
        if type(previous) ~= "table" then
            previous = ColorPickerFrame and ColorPickerFrame.previousValues
        end
        local pr, pg, pb = r, g, b
        if type(previous) == "table" then
            pr = previous.r or previous[1] or pr
            pg = previous.g or previous[2] or pg
            pb = previous.b or previous[3] or pb
        end
        onChange(pr, pg, pb)
    end
    if not ColorPickerFrame then
        return
    end
    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b,
            opacity = 1,
            hasOpacity = false,
            swatchFunc = apply,
            opacityFunc = apply,
            cancelFunc = cancel,
        })
        return
    end
    ColorPickerFrame.hasOpacity = false
    ColorPickerFrame.func = apply
    ColorPickerFrame.opacityFunc = apply
    ColorPickerFrame.cancelFunc = function()
        cancel()
    end
    ColorPickerFrame:SetColorRGB(r, g, b)
    ColorPickerFrame:Hide()
    ColorPickerFrame:Show()
end

local function CurrentCatalogMap()
    local mapID = C_Map.GetBestMapForUnit("player")
    if issecretvalue and issecretvalue(mapID) then
        return nil
    end
    return WCC.CatalogMap(mapID)
end

local function FirstZone()
    local expansions = WCC.expansions or {}
    local first = expansions[1]
    local zone = first and first.zones and first.zones[1]
    return zone and zone.mapID
end

local function SameColor(rows)
    if not rows or #rows == 0 then
        return WCC.PRESETS.pink[1], WCC.PRESETS.pink[2], WCC.PRESETS.pink[3], false
    end
    local r, g, b = rows[1].r, rows[1].g, rows[1].b
    for i = 2, #rows do
        if rows[i].r ~= r or rows[i].g ~= g or rows[i].b ~= b then
            return GILDED.accent[1], GILDED.accent[2], GILDED.accent[3], true
        end
    end
    return r, g, b, false
end

local zonePool = {}
local treasurePool = {}
local nearbyPool = {}
local newsPool = {}

local function EnsureSelection()
    if state.mapID and WCC.zoneByMap and WCC.zoneByMap[state.mapID] then
        return
    end
    state.mapID = CurrentCatalogMap() or FirstZone()
end

local function Draw()
    if not window then return end
    EnsureSelection()
    window:DrawZones()
    window:DrawTreasures(false)
    window:PaintToggle()
end

local function AfterEdit(keepScroll)
    WCC.Refresh()
    if window and window:IsShown() then
        window:DrawTreasures(keepScroll)
        window:DrawZones()
    end
end

function WCC.Toggle()
    if not window then
        WCC.BuildWindow()
    end
    if window:IsShown() then
        window:Hide()
    else
        state.nearby = false
        EnsureSelection()
        local here = CurrentCatalogMap()
        if here then
            state.mapID = here
        end
        window:Show()
        Draw()
    end
end

local function BuildNews()
    news = CreateFrame("Frame", "WorldColorCodeWhatsNew", UIParent)
    news:SetSize(440, 420)
    news:SetPoint("CENTER")
    news:SetFrameStrata("DIALOG")
    news:SetToplevel(true)
    news:SetMovable(true)
    news:EnableMouse(true)
    news:SetClampedToScreen(true)
    news:Hide()
    table.insert(UISpecialFrames, "WorldColorCodeWhatsNew")

    local bg = news:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    ApplyColor(bg, GILDED.bg)
    Box(news, GILDED.border)

    local titleBar = CreateFrame("Frame", nil, news)
    titleBar:SetHeight(TITLE_H)
    titleBar:SetPoint("TOPLEFT")
    titleBar:SetPoint("TOPRIGHT")
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() news:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() news:StopMovingOrSizing() end)
    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints()
    ApplyColor(titleBg, GILDED.headerBg)
    Edge(titleBar, "TOP", GILDED.accent, 2)
    Edge(titleBar, "BOTTOM", GILDED.border, 1)

    local titleText = titleBar:CreateFontString(nil, "OVERLAY")
    Face(titleText, 14)
    ApplyText(titleText, GILDED.accent)
    titleText:SetPoint("LEFT", 8, 0)
    titleText:SetText("What's new")

    local closeButton = CreateFrame("Button", nil, titleBar)
    closeButton:SetSize(16, 16)
    closeButton:SetPoint("RIGHT", -4, 0)
    local closeText = closeButton:CreateFontString(nil, "OVERLAY")
    Face(closeText, 12)
    ApplyText(closeText, GILDED.textSecondary)
    closeText:SetAllPoints()
    closeText:SetJustifyH("CENTER")
    closeText:SetText("x")
    closeButton:SetScript("OnEnter", function() ApplyText(closeText, GILDED.accent) end)
    closeButton:SetScript("OnLeave", function() ApplyText(closeText, GILDED.textSecondary) end)
    closeButton:SetScript("OnClick", function() news:Hide() end)

    local scroll = MakeScroll(news)
    scroll:SetPoint("TOPLEFT", PAD, -(TITLE_H + PAD))
    scroll:SetPoint("BOTTOMRIGHT", -PAD, PAD)

    local function lineRow(parent)
        local row = CreateFrame("Frame", nil, parent)
        row:SetHeight(16)
        local text = row:CreateFontString(nil, "OVERLAY")
        text:SetPoint("TOPLEFT")
        text:SetJustifyH("LEFT")
        text:SetJustifyV("TOP")
        text:SetWordWrap(true)
        row.text = text
        return row
    end

    function news:Draw()
        local child = scroll.child
        Release(newsPool)
        local width = ContentWidth(scroll, 400)
        child:SetWidth(width)
        local y = 4
        local notes = WCC.WHATS_NEW or {}
        for i = 1, #notes do
            local note = notes[i]
            local head = Acquire(newsPool, child, lineRow)
            head:ClearAllPoints()
            head:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
            head:SetWidth(width)
            Face(head.text, 13)
            ApplyText(head.text, GILDED.accent)
            head.text:SetWidth(width)
            head.text:SetText(WCC.WithPathArrows(note.version or "", 12))
            local height = math.max(16, head.text:GetStringHeight() or 0)
            head:SetHeight(height)
            y = y + height + 6
            local body = note.text or ""
            body = body:gsub("%*%*", "")
            for line in (body .. "\n"):gmatch("(.-)\n") do
                local trimmed = line:match("^%s*(.-)%s*$") or ""
                if trimmed ~= "" then
                    local row = Acquire(newsPool, child, lineRow)
                    row:ClearAllPoints()
                    row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
                    row:SetWidth(width)
                    row.text:SetWidth(width)
                    local section = trimmed == "New features" or trimmed == "Adjusted features" or trimmed == "Bug fixes"
                    local bullet = trimmed:match("^•%s*(.*)$")
                    if section then
                        Face(row.text, 12)
                        ApplyText(row.text, GILDED.accent)
                        row.text:SetText(WCC.WithPathArrows(trimmed, 12))
                    elseif bullet then
                        Face(row.text, 11)
                        ApplyText(row.text, GILDED.textPrimary)
                        row.text:SetText(WCC.WithPathArrows(bullet, 12))
                    else
                        Face(row.text, 12)
                        ApplyText(row.text, GILDED.textPrimary)
                        row.text:SetText(WCC.WithPathArrows(trimmed, 12))
                    end
                    height = math.max(16, row.text:GetStringHeight() or 0)
                    row:SetHeight(height)
                    y = y + height + (section and 8 or 4)
                end
            end
            y = y + 10
        end
        child:SetHeight(math.max(y, scroll:GetHeight() or 0))
        if scroll.UpdateScrollBar then scroll.UpdateScrollBar() end
        scroll:SetVerticalScroll(0)
    end
end

function WCC.BuildWindow()
    if window then return end
    BuildNews()

    window = CreateFrame("Frame", "WorldColorCodeFrame", UIParent)
    window:SetSize(WIDTH, HEIGHT)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetMovable(true)
    window:EnableMouse(true)
    window:SetClampedToScreen(true)
    window:Hide()
    table.insert(UISpecialFrames, "WorldColorCodeFrame")

    local bg = window:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    ApplyColor(bg, GILDED.bg)
    Box(window, GILDED.border)

    local titleBar = CreateFrame("Frame", nil, window)
    titleBar:SetHeight(TITLE_H)
    titleBar:SetPoint("TOPLEFT")
    titleBar:SetPoint("TOPRIGHT")
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() window:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() window:StopMovingOrSizing() end)
    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints()
    ApplyColor(titleBg, GILDED.headerBg)
    Edge(titleBar, "TOP", GILDED.accent, 2)
    Edge(titleBar, "BOTTOM", GILDED.border, 1)

    local titleText = titleBar:CreateFontString(nil, "OVERLAY")
    Face(titleText, 14)
    ApplyText(titleText, GILDED.accent)
    titleText:SetPoint("LEFT", 8, 0)
    titleText:SetText("World Color Code")

    local closeButton = CreateFrame("Button", nil, titleBar)
    closeButton:SetSize(16, 16)
    closeButton:SetPoint("RIGHT", -4, 0)
    local closeText = closeButton:CreateFontString(nil, "OVERLAY")
    Face(closeText, 12)
    ApplyText(closeText, GILDED.textSecondary)
    closeText:SetAllPoints()
    closeText:SetJustifyH("CENTER")
    closeText:SetText("x")
    closeButton:SetScript("OnEnter", function() ApplyText(closeText, GILDED.accent) end)
    closeButton:SetScript("OnLeave", function() ApplyText(closeText, GILDED.textSecondary) end)
    closeButton:SetScript("OnClick", function() window:Hide() end)

    local versionButton = CreateFrame("Button", nil, titleBar)
    versionButton:SetSize(70, 16)
    versionButton:SetPoint("RIGHT", closeButton, "LEFT", -4, 0)
    local versionText = versionButton:CreateFontString(nil, "OVERLAY")
    Face(versionText, 10)
    ApplyText(versionText, GILDED.textDim)
    versionText:SetAllPoints()
    versionText:SetJustifyH("RIGHT")
    versionText:SetText(AddonVersion())
    versionButton:SetScript("OnEnter", function() ApplyText(versionText, GILDED.accent) end)
    versionButton:SetScript("OnLeave", function() ApplyText(versionText, GILDED.textDim) end)
    versionButton:SetScript("OnClick", function()
        news:Draw()
        news:Show()
    end)

    local footer = CreateFrame("Button", nil, window)
    footer:SetHeight(FOOTER_H - 6)
    footer:SetPoint("BOTTOMLEFT", PAD, 6)
    footer:SetPoint("BOTTOMRIGHT", -PAD, 6)
    local footerBg = footer:CreateTexture(nil, "BACKGROUND")
    footerBg:SetAllPoints()
    ApplyColor(footerBg, GILDED.headerBg)
    Box(footer, GILDED.border)
    local footerLabel = footer:CreateFontString(nil, "OVERLAY")
    Face(footerLabel, 12)
    ApplyText(footerLabel, GILDED.textPrimary)
    footerLabel:SetPoint("LEFT", 8, 0)
    footerLabel:SetText("Minimap colors")
    local footerState = footer:CreateFontString(nil, "OVERLAY")
    Face(footerState, 12)
    footerState:SetPoint("RIGHT", -8, 0)
    footer:SetScript("OnEnter", function() ApplyColor(footerBg, GILDED.rowHover) end)
    footer:SetScript("OnLeave", function() ApplyColor(footerBg, GILDED.headerBg) end)
    footer:SetScript("OnClick", function()
        WCC.SetEnabled(not WCC.IsEnabled())
        WCC.Refresh()
        window:PaintToggle()
    end)

    function window:PaintToggle()
        if WCC.IsEnabled() then
            ApplyText(footerState, GILDED.accent)
            footerState:SetText("On")
        else
            ApplyText(footerState, GILDED.textDim)
            footerState:SetText("Off")
        end
    end

    local leftScroll = MakeScroll(window)
    leftScroll:SetPoint("TOPLEFT", PAD, -(TITLE_H + 6))
    leftScroll:SetPoint("BOTTOMLEFT", PAD, FOOTER_H)
    leftScroll:SetWidth(LEFT_W)

    local right = CreateFrame("Frame", nil, window)
    right:SetPoint("TOPLEFT", leftScroll, "TOPRIGHT", PAD, 0)
    right:SetPoint("BOTTOMRIGHT", -PAD, FOOTER_H)

    local rightHead = CreateFrame("Frame", nil, right)
    rightHead:SetHeight(28)
    rightHead:SetPoint("TOPLEFT")
    rightHead:SetPoint("TOPRIGHT")
    local headBg = rightHead:CreateTexture(nil, "BACKGROUND")
    headBg:SetAllPoints()
    ApplyColor(headBg, GILDED.headerBg)
    Edge(rightHead, "BOTTOM", GILDED.border, 1)

    local zoneSwatch = CreateFrame("Button", nil, rightHead)
    zoneSwatch:SetSize(16, 16)
    zoneSwatch:SetPoint("LEFT", 6, 0)
    local zoneFill = zoneSwatch:CreateTexture(nil, "ARTWORK")
    zoneFill:SetPoint("TOPLEFT", 2, -2)
    zoneFill:SetPoint("BOTTOMRIGHT", -2, 2)
    Box(zoneSwatch, GILDED.border)
    zoneSwatch:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    zoneSwatch:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Colors every treasure in this zone.", 1, 1, 1, 1, true)
        GameTooltip:AddLine("Right-click for the original colors.", 0.56, 0.56, 0.56, true)
        GameTooltip:Show()
    end)
    zoneSwatch:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local zoneTitle = rightHead:CreateFontString(nil, "OVERLAY")
    Face(zoneTitle, 12)
    ApplyText(zoneTitle, GILDED.textPrimary)
    zoneTitle:SetPoint("LEFT", zoneSwatch, "RIGHT", 8, 0)
    zoneTitle:SetJustifyH("LEFT")
    zoneTitle:SetWordWrap(false)

    local showAll = CreateFrame("Button", nil, rightHead)
    showAll:SetSize(72, 18)
    showAll:SetPoint("RIGHT", -4, 0)
    local showAllText = showAll:CreateFontString(nil, "OVERLAY")
    Face(showAllText, 11)
    showAllText:SetAllPoints()
    showAllText:SetJustifyH("RIGHT")
    showAll:SetScript("OnClick", function()
        state.showAll = not state.showAll
        window:DrawTreasures(false)
    end)

    local rightScroll = MakeScroll(right)
    rightScroll:SetPoint("TOPLEFT", rightHead, "BOTTOMLEFT", 0, -4)
    rightScroll:SetPoint("BOTTOMRIGHT", 0, 32)

    local bar = CreateFrame("Frame", nil, right)
    bar:SetHeight(24)
    bar:SetPoint("BOTTOMLEFT")
    bar:SetPoint("BOTTOMRIGHT")

    local addButton = CreateFrame("Button", nil, bar)
    addButton:SetSize(52, 22)
    addButton:SetPoint("RIGHT", -78, 0)
    local addBg = addButton:CreateTexture(nil, "BACKGROUND")
    addBg:SetAllPoints()
    ApplyColor(addBg, GILDED.headerBg)
    Box(addButton, GILDED.border)
    local addText = addButton:CreateFontString(nil, "OVERLAY")
    Face(addText, 11)
    ApplyText(addText, GILDED.textPrimary)
    addText:SetAllPoints()
    addText:SetJustifyH("CENTER")
    addText:SetText("Add")
    addButton:SetScript("OnEnter", function() ApplyColor(addBg, GILDED.rowHover) end)
    addButton:SetScript("OnLeave", function() ApplyColor(addBg, GILDED.headerBg) end)

    local nearbyButton = CreateFrame("Button", nil, bar)
    nearbyButton:SetSize(70, 22)
    nearbyButton:SetPoint("RIGHT", 0, 0)
    local nearbyBg = nearbyButton:CreateTexture(nil, "BACKGROUND")
    nearbyBg:SetAllPoints()
    ApplyColor(nearbyBg, GILDED.headerBg)
    Box(nearbyButton, GILDED.border)
    local nearbyText = nearbyButton:CreateFontString(nil, "OVERLAY")
    Face(nearbyText, 11)
    ApplyText(nearbyText, GILDED.textPrimary)
    nearbyText:SetAllPoints()
    nearbyText:SetJustifyH("CENTER")
    nearbyButton:SetScript("OnEnter", function() ApplyColor(nearbyBg, GILDED.rowHover) end)
    nearbyButton:SetScript("OnLeave", function() ApplyColor(nearbyBg, GILDED.headerBg) end)
    nearbyButton:SetScript("OnClick", function()
        state.nearby = not state.nearby
        window:DrawTreasures(false)
    end)

    local edit = CreateFrame("EditBox", nil, bar)
    edit:SetHeight(22)
    edit:SetPoint("LEFT", 0, 0)
    edit:SetPoint("RIGHT", addButton, "LEFT", -6, 0)
    edit:SetAutoFocus(false)
    edit:SetFont(FONT, 12, "")
    edit:SetShadowOffset(0, 0)
    edit:SetTextInsets(6, 6, 0, 0)
    edit:SetMaxLetters(80)
    ApplyText(edit, GILDED.textPrimary)
    local editBg = edit:CreateTexture(nil, "BACKGROUND")
    editBg:SetAllPoints()
    ApplyColor(editBg, GILDED.inputBg)
    Box(edit, GILDED.border)
    local hint = edit:CreateFontString(nil, "OVERLAY")
    Face(hint, 11)
    ApplyText(hint, GILDED.textDim)
    hint:SetPoint("LEFT", 6, 0)
    hint:SetText("Add a treasure name")

    local function CommitAdd()
        if not state.mapID then return end
        if WCC.AddTreasure(state.mapID, edit:GetText()) then
            edit:SetText("")
            hint:Show()
            AfterEdit(true)
        end
    end

    edit:SetScript("OnTextChanged", function(self)
        if Trim(self:GetText()) == "" then
            hint:Show()
        else
            hint:Hide()
        end
    end)
    edit:SetScript("OnEditFocusGained", function() hint:Hide() end)
    edit:SetScript("OnEditFocusLost", function(self)
        if Trim(self:GetText()) == "" then hint:Show() end
    end)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        CommitAdd()
    end)
    addButton:SetScript("OnClick", CommitAdd)

    local function ZoneRow(parent)
        local row = CreateFrame("Button", nil, parent)
        row:SetHeight(ZONE_H)
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", function(_, delta) Wheel(leftScroll, delta) end)
        local rowBg = row:CreateTexture(nil, "BACKGROUND")
        rowBg:SetAllPoints()
        row.bg = rowBg
        local label = row:CreateFontString(nil, "OVERLAY")
        Face(label, 12)
        label:SetPoint("LEFT", 8, 0)
        label:SetPoint("RIGHT", -4, 0)
        label:SetJustifyH("LEFT")
        label:SetWordWrap(false)
        row.label = label
        return row
    end

    local function HeaderRow(parent)
        local row = CreateFrame("Frame", nil, parent)
        row:SetHeight(HEAD_H)
        local label = row:CreateFontString(nil, "OVERLAY")
        Face(label, 11)
        ApplyText(label, GILDED.accent)
        label:SetPoint("LEFT", 4, 0)
        label:SetPoint("RIGHT", -4, 0)
        label:SetJustifyH("LEFT")
        row.label = label
        return row
    end

    local headerPool = {}

    function window:DrawZones()
        local child = leftScroll.child
        child:SetWidth(ContentWidth(leftScroll, LEFT_W))
        Release(zonePool)
        Release(headerPool)
        local here = CurrentCatalogMap()
        local y = 2
        local expansions = WCC.expansions or {}
        for e = 1, #expansions do
            local expansion = expansions[e]
            local header = Acquire(headerPool, child, HeaderRow)
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
            header:SetPoint("TOPRIGHT", child, "TOPRIGHT", 0, -y)
            header.label:SetText(expansion.name)
            y = y + HEAD_H
            local zones = expansion.zones or {}
            for z = 1, #zones do
                local zone = zones[z]
                local row = Acquire(zonePool, child, ZoneRow)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
                row:SetPoint("TOPRIGHT", child, "TOPRIGHT", 0, -y)
                row.label:SetText(zone.name)
                local selected = zone.mapID == state.mapID
                local standing = zone.mapID == here
                if standing then
                    ApplyColor(row.bg, GILDED.here)
                elseif selected then
                    ApplyColor(row.bg, GILDED.rowHover)
                else
                    ApplyColor(row.bg, GILDED.bg)
                end
                ApplyText(row.label, selected and GILDED.accent or GILDED.textPrimary)
                row:SetScript("OnClick", function()
                    state.mapID = zone.mapID
                    state.nearby = false
                    window:DrawZones()
                    window:DrawTreasures(false)
                end)
                y = y + ZONE_H
            end
        end
        child:SetHeight(math.max(y + 4, leftScroll:GetHeight() or 0))
        if leftScroll.UpdateScrollBar then leftScroll.UpdateScrollBar() end
    end

    local function TreasureRow(parent)
        local row = CreateFrame("Frame", nil, parent)
        row:SetHeight(ROW_H)
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", function(_, delta) Wheel(rightScroll, delta) end)
        local rowBg = row:CreateTexture(nil, "BACKGROUND")
        rowBg:SetAllPoints()
        row.bg = rowBg
        Edge(row, "BOTTOM", GILDED.border, 1)

        local swatch = CreateFrame("Button", nil, row)
        swatch:SetSize(16, 16)
        swatch:SetPoint("LEFT", 4, 0)
        local fill = swatch:CreateTexture(nil, "ARTWORK")
        fill:SetPoint("TOPLEFT", 2, -2)
        fill:SetPoint("BOTTOMRIGHT", -2, 2)
        Box(swatch, GILDED.border)
        swatch:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row.swatch = swatch
        row.fill = fill

        local hide = CreateFrame("Button", nil, row)
        hide:SetSize(46, 18)
        hide:SetPoint("RIGHT", -4, 0)
        local hideText = hide:CreateFontString(nil, "OVERLAY")
        Face(hideText, 11)
        hideText:SetAllPoints()
        hideText:SetJustifyH("RIGHT")
        row.hideText = hideText
        row.hide = hide

        local remove = CreateFrame("Button", nil, row)
        remove:SetSize(52, 18)
        remove:SetPoint("RIGHT", hide, "LEFT", -4, 0)
        local removeText = remove:CreateFontString(nil, "OVERLAY")
        Face(removeText, 11)
        ApplyText(removeText, GILDED.textSecondary)
        removeText:SetAllPoints()
        removeText:SetJustifyH("RIGHT")
        removeText:SetText("Remove")
        row.remove = remove

        local name = row:CreateFontString(nil, "OVERLAY")
        Face(name, 12)
        name:SetPoint("LEFT", swatch, "RIGHT", 8, 0)
        name:SetPoint("RIGHT", remove, "LEFT", -6, 0)
        name:SetJustifyH("LEFT")
        name:SetWordWrap(false)
        row.name = name
        return row
    end

    local function NearbyRow(parent)
        local row = CreateFrame("Button", nil, parent)
        row:SetHeight(ROW_H)
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", function(_, delta) Wheel(rightScroll, delta) end)
        local rowBg = row:CreateTexture(nil, "BACKGROUND")
        rowBg:SetAllPoints()
        row.bg = rowBg
        Edge(row, "BOTTOM", GILDED.border, 1)
        local name = row:CreateFontString(nil, "OVERLAY")
        Face(name, 12)
        name:SetPoint("LEFT", 8, 0)
        name:SetPoint("RIGHT", -64, 0)
        name:SetJustifyH("LEFT")
        name:SetWordWrap(false)
        row.name = name
        local mark = row:CreateFontString(nil, "OVERLAY")
        Face(mark, 11)
        mark:SetPoint("RIGHT", -6, 0)
        mark:SetJustifyH("RIGHT")
        row.mark = mark
        row:SetScript("OnEnter", function() ApplyColor(rowBg, GILDED.rowHover) end)
        row:SetScript("OnLeave", function() ApplyColor(rowBg, GILDED.bg) end)
        return row
    end

    function window:DrawTreasures(keepScroll)
        local scrollPos = keepScroll and rightScroll:GetVerticalScroll() or 0
        local child = rightScroll.child
        child:SetWidth(ContentWidth(rightScroll, WIDTH - LEFT_W - (PAD * 3)))
        Release(treasurePool)
        Release(nearbyPool)
        local mapID = state.mapID
        local zone = mapID and WCC.zoneByMap and WCC.zoneByMap[mapID]
        nearbyText:SetText(state.nearby and "Zone" or "Nearby")

        if state.nearby then
            zoneSwatch:Hide()
            zoneTitle:ClearAllPoints()
            zoneTitle:SetPoint("LEFT", 8, 0)
            zoneTitle:SetPoint("RIGHT", showAll, "LEFT", -8, 0)
            zoneTitle:SetText("Nearby")
            showAll:Show()
            ApplyText(showAllText, state.showAll and GILDED.accent or GILDED.textSecondary)
            showAllText:SetText(state.showAll and "Showing all" or "Show all")
            local names = WCC.Nearby(state.showAll)
            local y = 0
            if #names == 0 then
                local row = Acquire(nearbyPool, child, NearbyRow)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, 0)
                row:SetPoint("TOPRIGHT", child, "TOPRIGHT", 0, 0)
                ApplyText(row.name, GILDED.textDim)
                row.name:SetText("Nothing on your minimap matches.")
                row.mark:SetText("")
                row:SetScript("OnClick", nil)
                y = ROW_H
            end
            local rows = WCC.Rows(mapID)
            local have = {}
            for i = 1, #rows do
                if not rows[i].hidden then
                    have[rows[i].name] = true
                end
            end
            for i = 1, #names do
                local treasureName = names[i]
                local row = Acquire(nearbyPool, child, NearbyRow)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
                row:SetPoint("TOPRIGHT", child, "TOPRIGHT", 0, -y)
                row.name:SetText(treasureName)
                if have[treasureName] then
                    ApplyText(row.name, GILDED.textDim)
                    ApplyText(row.mark, GILDED.textDim)
                    row.mark:SetText("Added")
                    row:SetScript("OnClick", nil)
                else
                    ApplyText(row.name, GILDED.textPrimary)
                    ApplyText(row.mark, GILDED.accent)
                    row.mark:SetText("Add")
                    row:SetScript("OnClick", function()
                        WCC.AddTreasure(mapID, treasureName)
                        AfterEdit(true)
                    end)
                end
                y = y + ROW_H
            end
            child:SetHeight(math.max(y, rightScroll:GetHeight() or 0))
        else
            zoneSwatch:Show()
            zoneTitle:ClearAllPoints()
            zoneTitle:SetPoint("LEFT", zoneSwatch, "RIGHT", 8, 0)
            zoneTitle:SetPoint("RIGHT", -8, 0)
            zoneTitle:SetText(zone and zone.name or "")
            showAll:Hide()
            local rows = WCC.Rows(mapID)
            local r, g, b = SameColor(rows)
            zoneFill:SetColorTexture(r, g, b, 1)
            zoneSwatch:SetScript("OnClick", function(_, button)
                if not mapID then return end
                if button == "RightButton" then
                    WCC.ClearZoneColor(mapID)
                    AfterEdit(true)
                    return
                end
                local snapshot = {}
                for i = 1, #rows do
                    snapshot[#snapshot + 1] = {
                        name = rows[i].name,
                        r = rows[i].r, g = rows[i].g, b = rows[i].b,
                    }
                end
                PickColor(r, g, b, function(nr, ng, nb)
                    WCC.SetZoneColor(mapID, nr, ng, nb)
                    AfterEdit(true)
                end, function()
                    for i = 1, #snapshot do
                        local saved = snapshot[i]
                        WCC.SetColor(mapID, saved.name, saved.r, saved.g, saved.b)
                    end
                    AfterEdit(true)
                end)
            end)
            local y = 0
            for i = 1, #rows do
                local treasure = rows[i]
                local row = Acquire(treasurePool, child, TreasureRow)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
                row:SetPoint("TOPRIGHT", child, "TOPRIGHT", 0, -y)
                ApplyColor(row.bg, GILDED.bg)
                row.name:SetText(treasure.name)
                ApplyText(row.name, treasure.hidden and GILDED.textDim or GILDED.textPrimary)
                row.fill:SetColorTexture(treasure.r, treasure.g, treasure.b, 1)
                row.hideText:SetText(treasure.hidden and "Show" or "Hide")
                ApplyText(row.hideText, treasure.hidden and GILDED.accent or GILDED.textSecondary)
                row.name:ClearAllPoints()
                row.name:SetPoint("LEFT", row.swatch, "RIGHT", 8, 0)
                if treasure.added then
                    row.remove:Show()
                    row.name:SetPoint("RIGHT", row.remove, "LEFT", -6, 0)
                else
                    row.remove:Hide()
                    row.name:SetPoint("RIGHT", row.hide, "LEFT", -6, 0)
                end
                row.swatch:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Right-click for the original color.", 0.91, 0.91, 0.91, 1, true)
                    GameTooltip:Show()
                end)
                row.swatch:SetScript("OnLeave", function() GameTooltip:Hide() end)
                row.swatch:SetScript("OnClick", function(_, button)
                    if button == "RightButton" then
                        WCC.ClearColor(mapID, treasure.name)
                        AfterEdit(true)
                        return
                    end
                    PickColor(treasure.r, treasure.g, treasure.b, function(nr, ng, nb)
                        WCC.SetColor(mapID, treasure.name, nr, ng, nb)
                        AfterEdit(true)
                    end)
                end)
                row.hide:SetScript("OnClick", function()
                    WCC.SetHidden(mapID, treasure.name, not treasure.hidden)
                    AfterEdit(true)
                end)
                row.remove:SetScript("OnClick", function()
                    WCC.RemoveTreasure(mapID, treasure.name)
                    AfterEdit(true)
                end)
                y = y + ROW_H
            end
            child:SetHeight(math.max(y, rightScroll:GetHeight() or 0))
        end

        local maxScroll = math.max(0, child:GetHeight() - rightScroll:GetHeight())
        if scrollPos > maxScroll then scrollPos = maxScroll end
        if not keepScroll then scrollPos = 0 end
        rightScroll:SetVerticalScroll(scrollPos)
        if rightScroll.UpdateScrollBar then rightScroll.UpdateScrollBar() end
    end

    local watcher = CreateFrame("Frame", nil, window)
    watcher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    watcher:RegisterEvent("VIGNETTES_UPDATED")
    watcher:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
    watcher:SetScript("OnEvent", function(_, event)
        if not window:IsShown() then return end
        if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
            window:DrawZones()
        end
        if state.nearby then
            window:DrawTreasures(true)
        end
    end)
end

SLASH_WORLDCOLORCODE1 = "/wcc"
SLASH_WORLDCOLORCODE2 = "/worldcolor"
SlashCmdList.WORLDCOLORCODE = function()
    WCC.Toggle()
end
