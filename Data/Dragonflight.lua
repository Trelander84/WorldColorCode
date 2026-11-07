-- Dragonflight treasures you can loot again. One-time chests are not listed.

local Zone = WorldColorCode.Zone

local REPEAT = {
    { "Disturbed Dirt", "teal" },
    { "Expedition Scout's Pack", "cyan" },
    { "Magic-Bound Chest", "yellow" },
    { "War Supply Chest", "orange" },
}

WorldColorCode.AddExpansion("Dragonflight", {
    Zone(2022, "The Waking Shores", REPEAT),
    Zone(2023, "Ohn'ahran Plains", REPEAT),
    Zone(2024, "The Azure Span", {
        { "Disturbed Dirt", "teal" },
        { "Expedition Scout's Pack", "cyan" },
        { "Magic-Bound Chest", "yellow" },
        { "War Supply Chest", "orange" },
        { "Decay Covered Chest", "green" },
    }),
    Zone(2025, "Thaldraszus", REPEAT),
    Zone(2151, "The Forbidden Reach", {
        { "Forbidden Hoard", "teal" },
        { "Storm-Bound Chest", "cyan" },
    }),
    Zone(2133, "Zaralek Cavern", {
        { "Smelly Disturbed Dirt", "teal" },
        { "Smelly Treasure Chest", "cyan" },
    }),
    Zone(2200, "Emerald Dream", {
        { "Emerald Bounty", "teal" },
        { "Dreamseed Cache", "cyan" },
    }),
})
