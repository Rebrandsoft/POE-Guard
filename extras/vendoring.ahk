;
; vendoring.ahk, 9/29/2020 10:37 PM
;

addMenuItem("__vendoring", _("Trade quality gems"), "tradeGems")
addMenuItem("__vendoring", _("Trade divination cards"), "tradeDivinationCards")
addMenuItem("__vendoring", _("Trade full rare sets"), "tradeFullRareSets")
addMenuItem("__vendoring")
addMenuItem("__vendoring", _("Unstack divination cards"), "unstackCards")
addMenuItem("__vendoring")
addMenuItem("__vendoring", _("Sort items"), "sortItems")
addMenuItem("__vendoring", _("Dump useless items (< 1 Chaos)"), "dumpUselessItems")
addMenuItem("__vendoring")
addMenuItem("__vendoring", _("Dump inventory items"), "dumpInventoryItems")
addMenuItem("__vendoring", _("Dump stash tab items"), "dumpStashTabItems")

Hotkey, IfWinActive, ahk_class POEWindowClass
Hotkey, F6, dumpInventoryItems
Hotkey, ^F6, dumpStashTabItems
Hotkey, F7, tradeFullRareSets
Hotkey, IfWinActive

;addExtraMenu(_("Vendoring"), ":__vendoring")

class FullRareSets {

    types := ["Weapon", "Helmet", "BodyArmour", "Gloves", "Boots", "Belt", "Amulet", "Ring"]

    __new() {
        this.items := {}
        for i, type in this.types
            this.items[type] := []
    }

    add(item) {
        if (item.rarity != 2 || item.isQuiver)
            return

        if (item.isWeapon || item.isShield) {
            if (item.gripType == "2H")
                this.items["Weapon"].Push(item)
            else
                this.items["Weapon"].InsertAt(1, item)
        } else {
            type := item.isArmour ? item.subType : item.baseType
            if (item.itemLevel < 75)
                this.items[type].Push(item)
            else
                this.items[type].InsertAt(1, item)
        }
    }

    get() {
        rareItems := []
        isChaosRecipe := false
        for type, items in this.items {
            n := (type ~= "Weapon|Ring") ? 2 : 1
            loop, % n {
                if (Not isChaosRecipe) {
                    item := items.Pop()
                    isChaosRecipe := item.itemLevel < 75
                } else {
                    item := items.RemoveAt(1)
                }

                if (Not item) {
                    debug("!!! {} <b style=""color=red"">{}</b>.", _("Need more"), type)
                    return
                }

                rareItems.Push(item)
                if (item.gripType == "2H")
                    break
            }
        }

        return rareItems
    }
}

tradeGems() {
    ptask.activate()
    if (Not ptask.stash.open())
        return

    ptask.stash.switchTab(VendorTabGems)
    Sleep, 300
    tab := ptask.stash.Tab
    for i, item in tab.getItems() {
        if (item.isGem && item.level < 19 && item.quality > 0 && item.quality < 18) {
            tab.move(item)
            n += 1
        }
    }

    if (n > 0 && ptask.getVendor().sell()) {
        for i, item in ptask.inventory.getItems() {
            if (item.isGem && item.level < 19 && item.quality > 0)
                ptask.inventory.move(item)
        }
        ptask.getSell().accept()
    }
}

tradeDivinationCards() {
    ptask.activate()
    tab := ptask.stash.getTab(VendorTabDivinationCards)
    if (tab) {
        for i, item in tab.getItems() {
            if (item.isDivinationCard && item.stackCount == item.stackSize)
                n += 1
        }
    }

    if (Not tab || n > 0) {
        if (Not ptask.stash.open())
            return

        ptask.stash.switchTab(VendorTabDivinationCards)
        Sleep, 300
        tab := ptask.stash.Tab
        for i, item in ptask.stash.Tab.getItems() {
            if (item.isDivinationCard && item.stackCount == item.stackSize) {
                tab.move(item)
                n += 1
            }
        }
    }

    if (n > 0 && ptask.getVendor().tradeDivinationCards()) {
        Sleep, 100
        ingameUI := ptask.getIngameUI()
        ingameUI.getChild(61, 5).getPos(x, y)
        for i, item in ptask.inventory.getItems() {
            if (item.isDivinationCard && item.stackCount == item.stackSize) {
                ptask.inventory.move(item)
                Sleep, 100
                MouseClick(x, y)
                Sleep, 200
                MouseMove, x, y - 150, 0
                Sleep, 50
                SendInput, ^{Click}
                Sleep, 100
            }
        }
    }
}

tradeFullRareSets() {
    ptask.activate()
    if (Not ptask.stash.open())
        return

    ptask.stash.switchTab(VendorTabFullRareSets)
    Sleep, 500

    rareSets := new FullRareSets()
    tab := ptask.stash.Tab
    for i, item in tab.getItems()
        rareSets.add(item)

    vendor := ptask.getVendor()
    sell := ptask.getSell()
    loop {
        rareItems := rareSets.get()
        if (Not rareItems || Not ptask.stash.open())
            break

        for i, item in rareItems
            tab.move(item)

        ptask.inventory.use(ptask.inventory.findItem(_("A Valuable Combination")))
        if (Not vendor.sell())
            break

        for i, item in ptask.inventory.getItems()
            if (item.rarity == 2 && (Not item.isIdentified) && item.itemLevel >= 60)
                ptask.inventory.move(item)

        Sleep, 100
        offerItem := sell.getItems()[1]
        if (Not RegExMatch(offerItem.name, _("Chaos") "|" _("Exalted Shard")))
            break

        debug(_("Received") " <b>{} {}</b>", offerItem.stackCount, offerItem.name)
        sell.accept(true)
        SendInput, %CloseAllUIKey%
    }
}

dumpInventoryItems() {
    ptask.activate()
    for i, item in ptask.inventory.getItems() {
        ptask.inventory.move(item)
    }
}

dumpStashTabItems() {
    ptask.activate()
    if (Not ptask.stash.open())
        return

    tab := ptask.stash.Tab
    loop, 2 {
        for i, e in tab.getChilds() {
            if (e.item && (dumpAllItems || e.isHighlighted)) {
                e.getPos(x, y)
                MouseMove, x, y, 0
                Sleep, 30

                m := 1
                if (e.item.stackCount > 0)
                    m += e.item.stackCount // e.item.stackSize

                loop, % m {
                    if (ptask.inventory.freeCells() == 0)
                        return

                    SendInput, ^{Click}
                    n += 1
                    Sleep, 50
                }
            }
        }

        if (n > 0)
            break
        dumpAllItems := true
    }
}

unstackCards() {
    ptask.activate()
    if (Not ptask.stash.open())
        return

    tab := ptask.stash.Tab
    for i, item in tab.getItems() {
        if (item.name == _("Stacked Deck")) {
            index := item.index
            loop, % item.stackCount {
                tab.moveTo(index)
                MouseClick, Right
                Sleep, 100

                if (Not ptask.inventory.drop())
                    return
            }
        }
    }
    ptask.stashItems()
}

dumpUselessItems() {
    ptask.activate()
    if (Not ptask.stash.open())
        return

    tab := ptask.stash.Tab
    for i, e in tab.getChilds() {
        if (e.item && Not e.item.isCurrency) {
            if (e.item.price && e.item.price < 1) {
                debug("{}, {}", e.item.name, e.item.price)
                e.getPos(x, y)
                MouseMove, x, y, 0
                Sleep, 30

                SendInput, ^{Click}
                Sleep, 50
                if (ptask.inventory.freeCells() == 0)
                    return
            }
        }
    }
}


sortItems() {
    ptask.activate()
    if (Not ptask.stash.open())
        return

    tab := ptask.stash.Tab
    if (__tab.type > 2 && __tab.type != 7)
        return
    
    vals := []
    items := tab.getItems()
    loop, % tab.rows * tab.cols {
        aItem := items[A_Index]
        if (Not aItem.price || aItem.width > 1 || aItem.height > 1)
            items.Delete(A_Index)
    }

    for i, aItem in items
        vals[aItem.Index] := aItem.price

    debug("Begin sorting items...")
    t0 := A_Tickcount

    loop % tab.rows * tab.cols {
        offset := A_Index
        selected := A_Index
        loop % tab.rows * tab.cols - offset {
            if (Not items[A_Index + offset])
                continue

            if (Not items[selected]) {
                selected := A_Index + offset
                continue
            }

            if (vals[A_Index + offset] > vals[selected]
                || (vals[A_Index + offset] == vals[selected]
                    && items[A_Index + offset].Name <= items[selected].Name)) {
                selected := A_Index + offset
            }
        }

        if (A_Index == selected || items[selected].Name == items[A_Index].Name) {
            if (Not items[A_Index]) {
                if (itemPicked) {
                    tab.moveTo(A_Index)
                    SendInput, {Click}
                    ;debug("    Placed " A_Index ", " itemPicked.Name)
                }
                break
            }

            if (Not itemPicked
                || valPicked < vals[A_Index]
                || (valPicked == vals[A_Index] && itemPicked.Name >= items[A_Index].Name))
                continue
        }

        if (Not itemPicked) {
            tab.moveTo(selected)
            SendInput, {Click}
            Sleep, 30
            ;debug("    Picked up " selected ", " items[selected].Name)
            vals[selected] := ""
            items[selected] := ""
        } else if (valPicked < vals[selected] || (valPicked == vals[selected] && itemPicked.Name > items[selected].Name)) {
            tab.moveTo(selected)
            SendInput, {Click}
            Sleep, 30
            ;debug("    Swaped with " selected ", " items[selected].Name)
            vals[selected] := valPicked
            items[selected] := itemPicked
        }

        tab.moveTo(A_Index)
        SendInput, {Click}
        Sleep, 30
        ;if (items[A_Index])
        ;    debug("    Replaced " A_Index ", " items[A_Index].Name)
        ;else
        ;    debug("    Placed " A_Index ", " itemPicked.Name)
        valPicked := vals[A_Index]
        itemPicked := items[A_Index]
    }

    t1 := A_Tickcount
    debug("Sorting completed (total {} microseconds).", t1 - t0)
}
