-- The War Within treasures you can loot again. One-time chests are not listed.
-- A richer version of a chest uses the same color as the normal one.

local Zone = WorldColorCode.Zone

WorldColorCode.AddExpansion("The War Within", {
    Zone(2248, "Isle of Dorn", {
        { "Earthen Coffer", "teal" },
        { "Ladened Earthen Coffer", "teal" },
        { "Elemental Geode", "cyan" },
        { "Keeper's Stash", "yellow" },
    }),
    Zone(2214, "The Ringing Deeps", {
        { "Deep-Lost Satchel", "teal" },
        { "Brimming Deep-Lost Satchel", "teal" },
        { "Machine Speaker's Reliquary", "cyan" },
        { "Etched Machine Speaker's Reliquary", "cyan" },
        { "Pile of Refuse", "yellow" },
        { "Enormous Pile of Refuse", "yellow" },
    }),
    Zone(2215, "Hallowfall", {
        { "Arathi Treasure Hoard", "teal" },
        { "Brimming Arathi Treasure Hoard", "teal" },
        { "Concentrated Shadow", "cyan" },
        { "Potent Concentrated Shadow", "cyan" },
        { "Kobyss Ritual Cache", "yellow" },
        { "Overflowing Kobyss Ritual Cache", "yellow" },
    }),
    Zone(2255, "Azj-Kahet", {
        { "Stashed Loot", "teal" },
        { "Sureki Strongbox", "cyan" },
        { "Royal Sureki Strongbox", "cyan" },
        { "Threadspun Cache", "yellow" },
        { "Hunters Threadspun Cache", "yellow" },
    }),
    Zone(2346, "Undermine", {
        { "Magic-Bound Chest", "teal" },
        { "Shiny Trash Can", "cyan" },
        { "Overflowing Dumpster", "yellow" },
        { "S.C.R.A.P. Heap", "orange" },
        "Blackened Dice",
        "Suspicious Book",
        "Unexploded Fireworks",
        "Uncracked Cold Ones",
        "Fireworks Hat",
        "Muff's Auto-Locker",
        "Abandoned Toolbox",
        "Unsupervised Takeout",
        "Particularly Nice Lamp",
        "Crumpled Schematics",
        "Inert Plunger?",
        "Papa's Long-Lost Putter",
        "Marooned Floatmingo",
        "Potent Potable",
        "Lonely Tub",
        "Trick Deck of Cards",
    }),
    Zone(2369, "Siren Isle", {
        { "Runed Storm Cache", "teal" },
        { "Seafarer's Cache", "cyan" },
    }),
    Zone(2371, "K'aresh", {
        { "Ethereal Pocket-Storage", "teal" },
        { "Broker Exchequer", "cyan" },
    }),
})
