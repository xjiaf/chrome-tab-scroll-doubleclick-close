#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off

; ========================================================
; Initialization
; ========================================================
SetWorkingDir(A_ScriptDir)
global INI_FILE := "settings.ini"
global STARTUP_LNK := A_Startup . "\ChromeTabEnhancer.lnk"

; Create default config if missing
if !FileExist(INI_FILE) {
    IniWrite("1", INI_FILE, "Options", "DoubleClickClose")
    IniWrite("1", INI_FILE, "Options", "ScrollSwitchTab")
    IniWrite("0", INI_FILE, "Options", "RightClickClose")
    IniWrite("0", INI_FILE, "Options", "HideTrayIcon")
    IniWrite("EN", INI_FILE, "System", "Language")
}

; Read Settings
global Opt_Double   := IniRead(INI_FILE, "Options", "DoubleClickClose", "1")
global Opt_Scroll   := IniRead(INI_FILE, "Options", "ScrollSwitchTab", "1")
global Opt_Right    := IniRead(INI_FILE, "Options", "RightClickClose", "0")
global Opt_HideIcon := IniRead(INI_FILE, "Options", "HideTrayIcon", "0")
global Cur_Lang     := IniRead(INI_FILE, "System", "Language", "EN")

; ========================================================
; Language Data
; ========================================================
global LangData := Map(
    "ZH", Map(
        "Title",      "Chrome 增强脚本",
        "Double",     "启用双击关闭标签页",
        "Scroll",     "启用滚轮切换标签页",
        "Right",      "启用右键关闭标签页",
        "HideIcon",   "显示/隐藏托盘图标 (Ctrl+Alt+H)",
        "Startup",    "开机自动启动",
        "SwitchLang", "Switch to English",
        "Exit",       "退出",
        "Reload",     "重启脚本"
    ),
    "EN", Map(
        "Title",      "Chrome Tab Enhancer",
        "Double",     "Double-Click to Close Tab",
        "Scroll",     "Scroll to Switch Tabs",
        "Right",      "Right-Click to Close Tab",
        "HideIcon",   "Toggle Tray Icon (Ctrl+Alt+H)",
        "Startup",    "Run at Startup",
        "SwitchLang", "切换到中文",
        "Exit",       "Exit",
        "Reload",     "Reload Script"
    )
)

; ========================================================
; Tray Icon Management
; ========================================================
ToggleTrayIconState(*) {
    global Opt_HideIcon

    if (A_IconHidden) {
        A_IconHidden := false
        Opt_HideIcon := "0"
        UpdateTrayTip()
        BuildMenu()
        ToolTip("Tray Icon: Visible")
    } else {
        A_IconHidden := true
        Opt_HideIcon := "1"
        ToolTip("Tray Icon: Hidden (Press Ctrl+Alt+H to show)")
    }

    IniWrite(Opt_HideIcon, INI_FILE, "Options", "HideTrayIcon")
    SetTimer () => ToolTip(), -2000
}

; Apply hidden state on startup
if (Opt_HideIcon == "1") {
    A_IconHidden := true
} else {
    UpdateTrayTip()
    BuildMenu()
}

; ========================================================
; Global Hotkey
; ========================================================

; [Ctrl + Alt + H] Toggle Tray Icon
^!h::ToggleTrayIconState()

; ========================================================
; Menu Construction
; ========================================================
BuildMenu() {
    A_TrayMenu.Delete()
    T := LangData[Cur_Lang]

    A_TrayMenu.Add(T["Double"], ToggleDouble)
    A_TrayMenu.Add(T["Scroll"], ToggleScroll)
    A_TrayMenu.Add(T["Right"], ToggleRight)
    A_TrayMenu.Add()
    A_TrayMenu.Add(T["Startup"], ToggleStartup)
    A_TrayMenu.Add(T["HideIcon"], ToggleTrayIconState)
    A_TrayMenu.Add(T["SwitchLang"], ToggleLanguage)
    A_TrayMenu.Add()
    A_TrayMenu.Add(T["Reload"], (*) => Reload())
    A_TrayMenu.Add(T["Exit"], (*) => ExitApp())

    if (Opt_Double == "1")
        A_TrayMenu.Check(T["Double"])
    if (Opt_Scroll == "1")
        A_TrayMenu.Check(T["Scroll"])
    if (Opt_Right == "1")
        A_TrayMenu.Check(T["Right"])
    if (Opt_HideIcon == "1")
        A_TrayMenu.Check(T["HideIcon"])
    if FileExist(STARTUP_LNK)
        A_TrayMenu.Check(T["Startup"])
}

UpdateTrayTip() {
    A_IconTip := LangData[Cur_Lang]["Title"]
    try TraySetIcon("shell32.dll", 239)
}

; --- Settings Toggles ---
ToggleDouble(*) {
    global Opt_Double := (Opt_Double = "1" ? "0" : "1")
    BuildMenu()
    IniWrite(Opt_Double, INI_FILE, "Options", "DoubleClickClose")
}

ToggleScroll(*) {
    global Opt_Scroll := (Opt_Scroll = "1" ? "0" : "1")
    BuildMenu()
    IniWrite(Opt_Scroll, INI_FILE, "Options", "ScrollSwitchTab")
}

ToggleRight(*) {
    global Opt_Right := (Opt_Right = "1" ? "0" : "1")
    BuildMenu()
    IniWrite(Opt_Right, INI_FILE, "Options", "RightClickClose")
}

ToggleLanguage(*) {
    global Cur_Lang := (Cur_Lang = "ZH" ? "EN" : "ZH")
    IniWrite(Cur_Lang, INI_FILE, "System", "Language")
    UpdateTrayTip()
    BuildMenu()
}

ToggleStartup(*) {
    if FileExist(STARTUP_LNK) {
        try FileDelete(STARTUP_LNK)
    } else {
        try FileCreateShortcut(A_ScriptFullPath, STARTUP_LNK, A_ScriptDir)
    }
    BuildMenu()
}

; ========================================================
; Helper Functions
; ========================================================
IsOverTabBar() {
    MouseGetPos(,, &hWnd)
    if !WinActive("ahk_id " hWnd)
        return false
    try {
        minMax := WinGetMinMax("ahk_id " hWnd)
        MouseGetPos(, &yPos)
        if (minMax = 1) ; Maximized
            return (yPos >= 0 && yPos <= 28)
        else if (minMax = 0) ; Windowed
            return (yPos >= 0 && yPos <= 45)
    }
    return false
}

; ========================================================
; Chrome Context Hotkeys
; ========================================================
#HotIf WinActive("ahk_class Chrome_WidgetWin_1")

; --- Double-Click Tab Close ---
~LButton::
{
    if (Opt_Double != "1")
        return

    if (A_PriorHotkey == "~LButton" && A_TimeSincePriorHotkey < 300) {
        if IsOverTabBar() {
            try {
                winID := WinExist("A")
                stateBefore := WinGetMinMax(winID)

                Sleep(50)
                if !WinExist(winID)
                    return
                stateAfter := WinGetMinMax(winID)

                ; Ignore if window state changed (Max/Restore)
                if (stateBefore != stateAfter)
                    return

                Send("^w") ; Close Tab
            }
        }
    }
}

; --- Scroll Switch Tabs ---
WheelUp::
WheelDown::
{
    if (Opt_Scroll != "1") {
        Send("{" A_ThisHotkey "}")
        return
    }

    if IsOverTabBar() {
        if (A_ThisHotkey = "WheelDown")
            Send("^{PgDn}")
        else
            Send("^{PgUp}")
    } else {
        Send("{" A_ThisHotkey "}")
    }
}

; --- Right Click Close Tab ---
RButton::
{
    if (Opt_Right = "1" && IsOverTabBar()) {
        Send("{MButton}")
        return
    }
    Send("{RButton Down}")
    KeyWait("RButton")
    Send("{RButton Up}")
}
#HotIf