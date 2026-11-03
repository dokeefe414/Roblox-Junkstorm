--!strict
-- Central balance settings; safe to tweak between playtests.
return {
    StartingCapacity = 3,
    CapacityPerUpgrade = 2,
    MaxBagLevel = 6,
    UpgradeBaseCost = 60,

    ScavengeSeconds = 75,
    WarningSeconds = 15,
    StormSeconds = 18,
    RecoverySeconds = 7,
    LootRespawnSeconds = 9,
    LootSlots = 22,

    -- Weights affect the chance that each collected object type spawns.
    Items = {
        {name = "Rusty Can", value = 12, weight = 38, color = Color3.fromRGB(246, 165, 76)},
        {name = "Broken Drone", value = 25, weight = 28, color = Color3.fromRGB(94, 207, 243)},
        {name = "Charged Battery", value = 43, weight = 19, color = Color3.fromRGB(139, 247, 119)},
        {name = "Golden Toaster", value = 78, weight = 11, color = Color3.fromRGB(255, 223, 83)},
        {name = "Alien Core", value = 140, weight = 4, color = Color3.fromRGB(240, 109, 251)},
    },
}
