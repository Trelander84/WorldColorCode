-- Midnight treasures you can loot again. One-time chests are not listed.
-- Zones with an empty list are still here so a name can be added.

local Zone = WorldColorCode.Zone

WorldColorCode.AddExpansion("Midnight", {
    Zone(2395, "Eversong Woods", {}),
    Zone(2437, "Zul'Aman", {}),
    Zone(2413, "Harandar", {}),
    Zone(2405, "Voidstorm", {}),
    Zone(2512, "The Coiled Isle", {
        { "Cracked Canopic Jar", "teal" },
        { "Venom-Clotted Bauble", "cyan" },
        { "Singing Shell", "yellow" },
        { "Unfortunate Scout's Satchel", "pink" },
        { "Decrepit Cache", "orange" },
    }),
})
