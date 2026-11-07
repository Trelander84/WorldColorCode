-- Saved data, shipped colors, and the per-zone name index.
-- Catalog files call AddExpansion while this file loads. OnLoaded fills the saved table.

WorldColorCode = WorldColorCode or {}

local WCC = WorldColorCode

WCC.expansions = WCC.expansions or {}

-- Starting colors for farmable treasure kinds. Pink is the fallback.
WCC.PRESETS = {
    teal = { 0.16078431904316, 1, 0.90588241815567 },
    cyan = { 0, 1, 1 },
    yellow = { 1, 1, 0 },
    pink = { 0.96470594406128, 0.69019609689713, 1 },
    orange = { 0.95, 0.55, 0.15 },
    green = { 0.40, 0.85, 0.45 },
    violet = { 0.72, 0.48, 0.95 },
    red = { 0.95, 0.28, 0.22 },
    ice = { 0.55, 0.82, 1.0 },
}

local db

function WCC.Preset(key)
    return WCC.PRESETS[key] or WCC.PRESETS.pink
end

function WCC.Zone(mapID, name, treasures)
    local list = {}
    for i = 1, #treasures do
        local entry = treasures[i]
        if type(entry) == "string" then
            list[i] = { name = entry, color = "pink" }
        else
            list[i] = { name = entry[1], color = entry[2] or "pink" }
        end
    end
    return { mapID = mapID, name = name, treasures = list }
end

function WCC.AddExpansion(name, zones)
    WCC.expansions[#WCC.expansions + 1] = { name = name, zones = zones }
end

local function MapTable(bucket, mapID)
    local page = bucket[mapID]
    if not page then
        page = {}
        bucket[mapID] = page
    end
    return page
end

function WCC.Rebuild()
    local byMap = {}
    local zoneByMap = {}
    local rowsByMap = {}
    local shippedByMap = {}

    for e = 1, #WCC.expansions do
        local zones = WCC.expansions[e].zones
        for z = 1, #zones do
            local zone = zones[z]
            local mapID = zone.mapID
            local visible = {}
            local rows = {}
            local shipped = {}
            local colors = db and db.colors and db.colors[mapID]
            local hidden = db and db.hidden and db.hidden[mapID]
            local added = db and db.added and db.added[mapID]

            for i = 1, #zone.treasures do
                local treasure = zone.treasures[i]
                local preset = WCC.Preset(treasure.color)
                local color = (colors and colors[treasure.name]) or preset
                local isHidden = hidden and hidden[treasure.name] and true or false
                shipped[treasure.name] = true
                rows[#rows + 1] = {
                    name = treasure.name,
                    r = color[1], g = color[2], b = color[3],
                    defaultR = preset[1], defaultG = preset[2], defaultB = preset[3],
                    hidden = isHidden,
                    added = false,
                }
                if not isHidden then
                    visible[treasure.name] = color
                end
            end

            if added then
                local names = {}
                for treasureName in pairs(added) do
                    if not shipped[treasureName] then
                        names[#names + 1] = treasureName
                    end
                end
                table.sort(names)
                for i = 1, #names do
                    local treasureName = names[i]
                    local color = added[treasureName]
                    local isHidden = hidden and hidden[treasureName] and true or false
                    local pink = WCC.PRESETS.pink
                    rows[#rows + 1] = {
                        name = treasureName,
                        r = color[1], g = color[2], b = color[3],
                        defaultR = pink[1], defaultG = pink[2], defaultB = pink[3],
                        hidden = isHidden,
                        added = true,
                    }
                    if not isHidden then
                        visible[treasureName] = color
                    end
                end
            end

            byMap[mapID] = visible
            zoneByMap[mapID] = zone
            rowsByMap[mapID] = rows
            shippedByMap[mapID] = shipped
        end
    end

    WCC.byMap = byMap
    WCC.zoneByMap = zoneByMap
    WCC.rowsByMap = rowsByMap
    WCC.shippedByMap = shippedByMap
end

function WCC.OnLoaded()
    if type(WorldColorCodeDB) ~= "table" then
        WorldColorCodeDB = {}
    end
    db = WorldColorCodeDB
    if type(db.colors) ~= "table" then db.colors = {} end
    if type(db.hidden) ~= "table" then db.hidden = {} end
    if type(db.added) ~= "table" then db.added = {} end
    if not WCC.orderReversed then
        local expansions = WCC.expansions
        local count = #expansions
        for i = 1, math.floor(count / 2) do
            expansions[i], expansions[count - i + 1] = expansions[count - i + 1], expansions[i]
        end
        WCC.orderReversed = true
    end
    WCC.ready = true
    WCC.Rebuild()
end

function WCC.IsEnabled()
    return not db or db.enabled ~= false
end

function WCC.SetEnabled(on)
    if not db then return end
    db.enabled = on and true or false
end

function WCC.CatalogMap(mapID)
    for _ = 1, 10 do
        if type(mapID) ~= "number" or mapID <= 0 or (issecretvalue and issecretvalue(mapID)) then
            return nil
        end
        if WCC.zoneByMap and WCC.zoneByMap[mapID] then
            return mapID
        end
        local info = C_Map.GetMapInfo(mapID)
        mapID = info and info.parentMapID
    end
    return nil
end

function WCC.Rows(mapID)
    return WCC.rowsByMap and WCC.rowsByMap[mapID] or {}
end

local function WriteColor(mapID, name, r, g, b)
    local added = db.added[mapID]
    if added and added[name] then
        added[name][1], added[name][2], added[name][3] = r, g, b
    else
        MapTable(db.colors, mapID)[name] = { r, g, b }
    end
end

local function WriteClear(mapID, name)
    local added = db.added[mapID]
    if added and added[name] then
        local pink = WCC.PRESETS.pink
        added[name][1], added[name][2], added[name][3] = pink[1], pink[2], pink[3]
    elseif db.colors[mapID] then
        db.colors[mapID][name] = nil
    end
end

function WCC.SetColor(mapID, name, r, g, b)
    if not db or not mapID or not name or name == "" then return end
    WriteColor(mapID, name, r, g, b)
    WCC.Rebuild()
end

function WCC.ClearColor(mapID, name)
    if not db or not mapID or not name then return end
    WriteClear(mapID, name)
    WCC.Rebuild()
end

function WCC.SetZoneColor(mapID, r, g, b)
    if not db or not mapID then return end
    local rows = WCC.Rows(mapID)
    for i = 1, #rows do
        WriteColor(mapID, rows[i].name, r, g, b)
    end
    WCC.Rebuild()
end

function WCC.ClearZoneColor(mapID)
    if not db or not mapID then return end
    local rows = WCC.Rows(mapID)
    for i = 1, #rows do
        WriteClear(mapID, rows[i].name)
    end
    WCC.Rebuild()
end

function WCC.SetHidden(mapID, name, hidden)
    if not db or not mapID or not name or name == "" then return end
    local page = MapTable(db.hidden, mapID)
    page[name] = hidden and true or nil
    WCC.Rebuild()
end

function WCC.AddTreasure(mapID, name)
    if not db or not mapID or type(name) ~= "string" then return false end
    name = name:match("^%s*(.-)%s*$") or ""
    if name == "" then return false end
    local shipped = WCC.shippedByMap and WCC.shippedByMap[mapID]
    if shipped and shipped[name] then
        if db.hidden[mapID] then
            db.hidden[mapID][name] = nil
        end
    else
        local page = MapTable(db.added, mapID)
        if not page[name] then
            local pink = WCC.PRESETS.pink
            page[name] = { pink[1], pink[2], pink[3] }
        end
        if db.hidden[mapID] then
            db.hidden[mapID][name] = nil
        end
    end
    WCC.Rebuild()
    return true
end

function WCC.RemoveTreasure(mapID, name)
    if not db or not mapID or not name then return end
    local added = db.added[mapID]
    if not added or not added[name] then return end
    added[name] = nil
    if db.hidden[mapID] then db.hidden[mapID][name] = nil end
    if db.colors[mapID] then db.colors[mapID][name] = nil end
    WCC.Rebuild()
end
