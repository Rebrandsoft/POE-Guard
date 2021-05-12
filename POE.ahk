#SingleInstance force
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent ; Stay open in background
#IfWinActive, Path of Exile ahk_class POEWindowClass

If (Not A_IsAdmin) {
    try {
        Run *RunAs "%A_AhkPath%" "%A_ScriptFullPath%"
        ExitApp
    }
}

SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Client
CoordMode, Pixel, Client

I_Icon = %A_ScriptDir%\images\clarity_skill_icon.ico
IfExist, %I_Icon%
Menu, Tray, Icon, %I_Icon%
;return

#Include, %A_ScriptDir%\lib\PoEapi.ahk
#Include, %A_ScriptDir%\Settings.ahk

EnvGet, homepath, USERPROFILE
FileRead, production_config, %HOMEPATH%\Documents\My Games\Path of Exile\production_Config.ini
production_config := SubStr(production_config, 1)
FileAppend, %production_config%, %A_ScriptDir%\production_config.ini
IniRead, close_panels, %A_ScriptDir%\production_config.ini, ACTION_KEYS, close_panels
IniRead, open_inventory_panel, %A_ScriptDir%\production_config.ini, ACTION_KEYS, open_inventory_panel
IniRead, use_temporary_skill1, %A_ScriptDir%\production_config.ini, ACTION_KEYS, use_temporary_skill1
IniRead, use_temporary_skill2, %A_ScriptDir%\production_config.ini, ACTION_KEYS, use_temporary_skill1
IniRead, language, %A_ScriptDir%\production_config.ini, LANGUAGE, language, en
FileDelete, %A_ScriptDir%\production_config.ini

global CloseAllUIKey := Chr(close_panels)
global InventoryKey := Chr(open_inventory_panel)
global DropFlareKey := Chr(use_temporary_skill1)
global DropDynamiteKey := Chr(use_temporary_skill2)

loadLibrary("libintl-8.dll")
DllCall("msvcrt\_putenv", "AStr", "LANG=" language)
DllCall("libintl-8\bindtextdomain", "AStr", "PoEapikit", "AStr", "./locale")
DllCall("libintl-8\textdomain", "AStr", "PoEapikit")
DllCall("AddFontResource", "Str", A_ScriptDir "\fonts\Fontin-SmallCaps.ttf")
DllCall("poeapi\poeapi_get_version", "int*", major_version, "int*", minor_version, "int*", patchlevel)

global logger := new Logger("PoEGuard By WildRage(D.K) log")
global ptask := new PoETask()

global version := "1.2.3"
global poeapiVersion := Format("{}.{}.{}", major_version, minor_version, patchlevel)
syslog("<b>PoEGuard v{} (" _("Powered by WildRage (D.K)") " POE-Guard v{})</b>", version, poeapiVersion)

Hotkey, IfWinActive, ahk_class POEWindowClass
Hotkey, ~%AttackSkillKey%, Attack
if (SecondaryAttackSkillKey)
    Hotkey, ~%SecondaryAttackSkillKey%, Attack
Hotkey, $%QuickDefenseKey%, QuickDefense
Hotkey, ~%AutoPickupKey%, AutoPickup
Hotkey, IfWinActive

#Include, %A_ScriptDir%\extras\vendoring.ahk
#Include, %A_ScriptDir%\extras\Pricer.ahk
#Include, %A_ScriptDir%\extras\Trader.ahk
#Include, %A_ScriptDir%\extras\Updater.ahk

OnExit("__Exit")

; end of auto-execute section
return

_(str) {
    return DllCall("libintl-8\gettext", "AStr", str, "AStr")
}

$(item) {
    return pricer.getPrice(item)
}

__Exit() {
    global __libs

    ptask.stop()
    DllCall("RemoveFontResource", "Str", A_ScriptDir "\fonts\Fontin-SmallCaps.ttf")
    for filename, h in __libs
        DllCall("FreeLibrary", "Ptr", h)
}

loadLibrary(filename) {
    global __libs

    if (Not __libs)
        __libs := {}

    h := DllCall("LoadLibrary", "Str", filename, "Ptr")
    __libs[filename] := h

    return h
}

objdump(obj, prefix = "", depth = 0) {
    if (Not IsObject(obj)) {
        debug("Not an object")
        return
    }

    baseClasses := ""
    base := obj.base
    loop {
        if (Not base)
            break
        baseClasses .= " -> " base.__Class
        base := base.base
    }

    debug("{}{:#x}{}:", prefix, &obj, baseClasses)
    for k, v in obj {
        try {
            debug("{}   {}{}, {}", prefix, IsObject(v) ? "*" : " ", k, IsObject(v) ? v.Count() : v)
            if (depth > 0 && IsObject(v))
                objdump(v, prefix "    ", depth - 1)
        } catch {}
    }
}

Attack:
    if (ptask.InMap)
        ptask.onAttack()
return

QuickDefense:
    SendInput, %QuickDefenseAction%
return

AutoPickup:
    ptask.levelupGems()
    ptask.beginPickup()
return

AutoClick() {
    MouseGetPos, x0, y0
    Loop {
        if (Not GetKeyState("Ctrl", "P"))
            break

        MouseGetPos, x, y
        if (abs(x - x0) > 100 || abs(y - y0) > 100)
            break

        x0 := x
        y0 := y
        if (GetKeyState("Shift", "P"))
            SendInput, ^+{Click}
        else
            SendInput, ^{Click}
        Sleep, 30
    }
}

~LButton::
    if (GetKeyState("LButton", "P"))
        ptask.stopPickup()
return


F2::
    SendInput, %AruasKey%
return


F5::
    ptask.sendKeys("/hideout")
return

~^LButton::
    If (A_PriorHotKey = A_ThisHotKey and A_TimeSincePriorHotkey < 200)
        SetTimer, AutoClick, -200
return

^m::
    ptask.toggleMaphack()
return

+-::_
-::NumpadSub
+::NumpadAdd

^WheelDown::SendInput {Right}
^WheelUp::SendInput {Left}

#IfWinActive

>^r::
Reload() {
    Reload
}

>^q::
ExitApp() {
    ExitApp
}

F12::
    logger.show()
return