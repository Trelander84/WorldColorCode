-- Shadowlands treasures you can loot again. One-time chests are not listed.
-- A zone with an empty list is still here so a name can be added.

local Zone = WorldColorCode.Zone

WorldColorCode.AddExpansion("Shadowlands", {
    Zone(1533, "Bastion", {}),
    Zone(1536, "Maldraxxus", {}),
    Zone(1565, "Ardenweald", {}),
    Zone(1525, "Revendreth", {}),
    Zone(1543, "The Maw", {
        { "Rift Hidden Cache", "teal" },
        { "Stolen Anima Vessel", "cyan" },
    }),
    Zone(1961, "Korthia", {
        { "Invasive Mawshroom", "teal" },
        { "Mawsworn Cache", "cyan" },
        { "Nest of Unusual Materials", "yellow" },
        { "Pile of Bones", "pink" },
        { "Relic Cache", "orange" },
        { "Shardhide Stash", "green" },
        { "Riftbound Cache", "violet" },
        { "Helsworn Chest", "red" },
        { "Stolen Anima Vessel", "ice" },
    }),
    Zone(1970, "Zereth Mortis", {
        { "Avian Nest", "teal" },
        { "Cypher-Bound Chest", "cyan" },
        { "Discarded Automa Scrap", "yellow" },
        { "Forgotten Treasure Vault", "pink" },
        { "Mawsworn Supply Chest", "orange" },
        { "Prying Eye Discovery", "green" },
        { "Pulp-Covered Relic", "violet" },
        { "Tarachnid Eggs", "red" },
        { "Sandworn Chest", "ice" },
        { "Locked Provis Cache", "teal" },
    }),
})
