; Plugins
global PluginOptions := { "AutoFlask"     : { "enabled" : false}
                        , "AutoOpen"      : { "enabled" : true, "range" : 15
                                            , "ignoredChests" : "Amphora"
                                            , "chest"   : false
                                            , "delveChestOnly" : true
                                            , "door"    : true }
                        , "AutoPickup"    : { "enabled" : true, "range" : 50
                                            , "ignoreChests"      : true
                                            , "strictLevel"       : 0
                                            , "genericItemFilter" : "Incubator|Quicksilver|Basalt|Quartz|(Divine|Eternal) Life"
                                            , "rareItemFilter"    : "Jewel|Amulet|Ring|Belt" }
                        , "KillCounter"   : { "enabled" : true, "radius" : 50 }
                        , "MinimapSymbol" : { "enabled" : true
                                            , "showNPC"            : false
                                            , "showPlayer"         : false
                                            , "showMonsters"       : true
                                            , "showMinions"        : false
                                            , "showCorpses"        : false
                                            , "rarity"             : 0
                                            , "showDelveChests"    : true
                                            , "showHeistChests"    : true
                                            , "minSize"            : 4
                                            , "ignoredDelveChests" : "Armour|Weapon|Generic|NoDrops|Encounter" }
                        , "PlayerStatus"  : { "enabled" : true
                                            , "autoQuitThresholdPercentage" : 25
                                            , "autoQuitMinLevel"   : 80 } }

; Attack and defense
;global QuickDefenseKey := "q"
;global QuickDefenseAction := "qe2345"
global AruasKey := "^q^w^e^r^t"

; Delve
global AutoDropFlare := true
global MaxDarknessStacks := 10

; Heist Chests
global HeistChestNameRegex := "HeistChest(Secondary|RewardRoom)(.*)(Military|Robot|Science|Thug)"

; Auto pickup
; Some items are picked up by default, includes:
;     1. all currency items, divination cards and map items
;     2. unique items
;     3. 6 sockets, 6 linked or 3 linked R-G-B items
;     4. gems whose quality > 5 or level > 12
;     5. All weapon/armour items whose item level are between 60 to 75
;     6. Influenced items
;
global AutoPickupKey := "a"
