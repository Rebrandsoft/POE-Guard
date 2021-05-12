;
; debug.ahk, 10/21/2020 9:10 PM
;

#Include, %A_ScriptDir%\extras\Eval.ahk

addMenuItem("__debug", _("Console"), "openConsole")
addMenuItem("__debug", _("IngameUI Inspector"), "openInspector")
addMenuItem("__debug")
addMenuItem("__debug", _("List inventory items"), "listInventoryItems")
addMenuItem("__debug", _("List inventory slots"), "listInventorySlots")
addMenuItem("__debug")
addMenuItem("__debug", _("List stash tab items"), "listStashTabItems")
addMenuItem("__debug", _("List stash tabs"), "listStashTabs")
addMenuItem("__debug")
addMenuItem("__debug", _("List vendor services"), "listVendorServices")
addMenuItem("__debug")
addMenuItem("__debug", _("List flasks"), "listFlasks")
addMenuItem("__debug", _("List flask slot"), "listFlaskSlot")

Hotkey, ^d, openConsole
Hotkey, ^i, openInspector

addExtraMenu(_("Debug"), ":__debug")

class IngameUIInspector extends AhkGui {

    elements := {}

    __new() {
        global

        base.__new("IngameUI Inspector")
        Gui, Margin, 5, 5
        Gui, Color, White
        Gui, Font, s9, Courier New
        Gui, Add, TreeView, % "r20 w400 h600 AltSubmit vIngameUITree gL1 v" this.__var("onSelected")
        Gui, Add, Edit, % "ys w300 h300 ReadOnly Multi Hwnd" this.__var("elementInfo")

        ingameUI := ptask.getIngameUI()
        this.addElement(ingameUI, 0, "IngameUI", 0, 2)
    }

    addElement(e, index, label = "", parentId = 0, depth = 1) {
        label := label ? "<" label "> " e.getText() : e.getText()
        itemId := TV_Add(Format("{:d}. {:X} {}", index, e.address, label), parentId, "Expand")
        e.getChilds()
        this.elements[itemId] := e

        if (depth > 0) {
            for i, c in e.childs
                this.addElement(c, i,, itemId, depth - 1)
        }
    }

    expandAll(itemId) {
        if (Not itemId)
            return

        TV_Modify(itemId, "Expand")
        itemId := TV_GetChild(itemId)
        loop, {
            if (Not itemId)
                break

            this.expandAll(itemId)
            itemId := TV_GetNext(itemId)
        }
    }

    onSelected() {
        if (A_GuiEvent == "S") {
            e := this.elements[A_EventInfo]
            r := e.getPos()
            GuiControl,, % this.elementInfo
                , % Format("Address: {:x}`nText: {}`nX: {}`nY: {}`nWidth: {}`nHeight: {}`nChilds: {}"
                , e.address, e.getText(), r.l, r.t, r.w, r.h, e.childs.Count())

            ptask.c.clear()
            e.draw()
        } else if (A_GuiEvent == "DoubleClick") {
            e := this.elements[A_EventInfo]
            if (Not TV_GetChild(A_EventInfo) && e.childs.Count() > 0)
                for i, c in e.childs
                    this.addElement(c, i,, A_EventInfo, 1)
            this.expandAll(A_EventInfo)
        }
    }

    drawElement() {
        itemId := TV_GetSelection()
        if (itemId == 0)
            return

        e := this.elements[itemId]
        e.draw()
    }
}

class Console extends AhkGui {

    static __history := {}
    static __index := 0

    __new() {
        global

        base.__new("Console")
        Gui, Margin, 5
        Gui, Font, s10, Calibri
        Gui, Add, ActiveX, Border VScroll r20 w700 v__mshtml, about:
        Gui, Add, Edit, % "-WantReturn w625 HwndinputHwnd v" this.__var("input")
        Gui, Add, Button, % "Default x+10 yp+0 gL1 v" this.__var("execute"), Execute

        this.hInput:= inputHwnd
        this.doc := __mshtml.Document
        this.doc.write("<pre style=""font-family:Consolas; font-size:18px; line-height:1.2"">")

        this.onMessage(0x100, "onKeyDown")
    }

    onKeyDown(keyCode, lParam, message, hwnd) {
        static EM_SETSEL = 0xb1
        static EM_SCROLL := 0xb5
        static EM_REPLACESEL := 0xC2

        if (hwnd == this.hInput) {
            if (keyCode == 0x26 && Console.__index > 1) {
                GuiControl,, % this.__var("input"), % this.__history[--Console.__index]
                len := DllCall("GetWindowTextLength", "uint", this.hInput)
                SendMessage, EM_SETSEL, len, len,, % "ahk_id " this.hInput
                return 0
            } else if (keyCode == 0x28 && Console.__index > 0 && Console.__index < this.__history.Count()) {
                GuiControl,, % this.__var("input"), % this.__history[++Console.__index]
                len := DllCall("GetWindowTextLength", "uint", this.hInput)
                SendMessage, EM_SETSEL, len, len,, % "ahk_id " this.hInput
                return 0
            } else if (keyCode == 0x1b) {
                GuiControl,, % this.__var("input")
            }
        }
    }

    execute() {
        guiId := this.Hwnd
        Gui, %guiId%:Submit, NoHide
        if (Not Trim(this.input))
            return

        this.doc.write(Format("<b>></b> {}`n", this.input))
        this.__history.Push(this.input)
        Console.__index := this.__history.Count() + 1
        result := Eval(this.input)
        result := StrJoin(result, "`n")
        if (result)
            this.doc.write(Format("<i style=""color:red"">{}`n</i>", result))
        this.doc.parentWindow.scrollTo(0, this.doc.body.scrollHeight)
        GuiControl,, % this.__var("input")
    }
}

openConsole() {
    con := new Console()
    con.show()
}

openInspector() {
    inspector := new IngameUIInspector()
    inspector.show()
}

listInventoryItems() {
    debug(_("Inventory:"))
    items := ptask.inventory.getItems()
    if (items.Count() == 0) {
        debug("    " _("No items"))
        Return
    }

    for i, item in items
        debug("    {:2d}. {}", item.index, item.name)
}

listInventorySlots() {
    debug(_("Inventory slots:"))
    for i, slot in ptask.inventories
        debug("    {:2d}. {}, {}, {}", slot.id, slot.rows, slot.cols, slot.items.Count())
}

listStashTabItems() {
    debug(_("Stash tab name:") " {}", ptask.stash.Tab.name)
    for i, item in ptask.stash.Tab.getItems()
        debug("    {:3d}. {}", item.index, item.name)
}

listStashTabs() {
    stashTabs := ptask.getStashTabs()
    if (stashTabs.Count() == 0) {
        debug(_("No stash tabs"))
        Return
    }

    debug(_("Stash tabs:"))
    for i, tab in stashTabs {
        debug("    {:2d}. {:2d}, <b>{:-32s}</b>, {:-#4x}, {:-#4x}, {:#x}", i
              , tab.index
              , tab.name
              , tab.type
              , tab.flags
              , tab.affinities)
        for j, t in tab.tabs
            debug("    {:2d}.{:d}.  {:2d}, {:-29s}, {:-#4x}, {:-#4x}, {:#x}", i, j
                  , t.index
                  , t.name
                  , t.type
                  , t.flags
                  , t.affinities)
    }
}

listVendorServices() {
    vendor := ptask.getVendor()
    if (Not vendor.name) {
        debug(_("No vendor selected."))
        return
    }

    debug(_("{}'s services:"), vendor.name)
    for name in vendor.getServices()
        debug("    {}. {}", A_Index, name)
}

listFlasks() {
    if (ptask.player.flasks.Count() == 0) {
        debug(_("No flasks"))
        Return
    }

    debug(_("Flasks:"))
    for i, flask in ptask.player.flasks
        debug("    {}. {:2d}, {:2d}, {}, {}, {}"
              , flask.key
              , flask.item.charges
              , flask.chargesPerUse
              , flask.maxCharges
              , flask.duration
              , flask.item.name)
}

listFlaskSlot() {
    ptask.inventories[12].getItems()
    debug(_("Flask slot:"))
    if (ptask.inventories[12].Count() == 0) {
        debug("    " _("No items"))
        Return
    }

    for i, item in ptask.inventories[12].items
        debug("    {}. {}", item.index, item.name)
}
