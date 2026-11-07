-- Minimap tint overlays. Same pin path as the TresTools Undermine test.

WorldColorCode = WorldColorCode or {}

local WCC = WorldColorCode

local pins = LibStub and LibStub("HereBeDragons-Pins-2.0", true)
local ref = "WorldColorCode"
local icons = {}
local warned = false

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function Plain(value)
    if type(value) ~= "string" or value == "" or IsSecret(value) then
        return nil
    end
    return value
end

local function IsKillAtlas(atlas)
    return atlas and atlas:find("Kill", 1, true) ~= nil
end

local function GetIcon(index)
    local icon = icons[index]
    if icon then
        return icon
    end

    icon = CreateFrame("Frame", nil, Minimap)
    icon:SetSize(16, 16)
    icon:SetFrameLevel(Minimap:GetFrameLevel() + 10)
    local texture = icon:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints()
    texture:SetTexelSnappingBias(0)
    texture:SetSnapToPixelGrid(false)
    icon.texture = texture
    icon:Hide()

    icons[index] = icon
    return icon
end

function WCC.Refresh()
    if not pins then
        if not warned then
            warned = true
            print("World Color Code could not load its map pins.")
        end
        return
    end
    pins:RemoveAllMinimapIcons(ref)
    if not WCC.ready or not WCC.IsEnabled() then
        return
    end

    local mapID = C_Map.GetBestMapForUnit("player")
    if IsSecret(mapID) then
        return
    end
    local catalogMap = WCC.CatalogMap(mapID)
    if not catalogMap then
        return
    end
    local names = WCC.byMap and WCC.byMap[catalogMap]
    if not names then
        return
    end

    local guids = C_VignetteInfo.GetVignettes()
    if not guids then
        return
    end

    local used = 0
    for _, guid in ipairs(guids) do
        if not IsSecret(guid) then
            local info = C_VignetteInfo.GetVignetteInfo(guid)
            local onMinimap = info and not IsSecret(info.onMinimap) and info.onMinimap
            local name = onMinimap and Plain(info.name)
            local color = name and names[name]
            local atlas = color and Plain(info.atlasName)
            local pos = atlas and C_VignetteInfo.GetVignettePosition(guid, mapID)
            if pos and not IsSecret(pos.x) and not IsSecret(pos.y) then
                used = used + 1
                local icon = GetIcon(used)
                icon.texture:SetAtlas(atlas)
                icon.texture:SetVertexColor(color[1], color[2], color[3])
                pins:AddMinimapIconMap(ref, icon, mapID, pos.x, pos.y, true, true)
            end
        end
    end
end

function WCC.Nearby(showAll)
    local found = {}
    local order = {}
    local guids = C_VignetteInfo.GetVignettes()
    if not guids then
        return order
    end
    for _, guid in ipairs(guids) do
        if not IsSecret(guid) then
            local info = C_VignetteInfo.GetVignetteInfo(guid)
            local onMinimap = info and not IsSecret(info.onMinimap) and info.onMinimap
            local name = onMinimap and Plain(info.name)
            local atlas = name and Plain(info.atlasName)
            if name and not found[name] and (showAll or not IsKillAtlas(atlas)) then
                found[name] = true
                order[#order + 1] = name
            end
        end
    end
    table.sort(order)
    return order
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("VIGNETTES_UPDATED")
frame:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "WorldColorCode" then
            WCC.OnLoaded()
            WCC.Refresh()
        end
        return
    end
    if WCC.ready then
        WCC.Refresh()
    end
end)
