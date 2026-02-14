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
; 0 = Off, 1 = Chrome Only, 2 = Edge Only, 3 = Both
if !FileExist(INI_FILE) {
    IniWrite("3", INI_FILE, "Options", "DoubleClickClose")
    IniWrite("3", INI_FILE, "Options", "ScrollSwitchTab")
    IniWrite("0", INI_FILE, "Options", "RightClickClose")
    IniWrite("0", INI_FILE, "Options", "HideTrayIcon")
    IniWrite("EN", INI_FILE, "System", "Language")
}

; Read Settings
global Opt_Double   := IniRead(INI_FILE, "Options", "DoubleClickClose", "3")
global Opt_Scroll   := IniRead(INI_FILE, "Options", "ScrollSwitchTab", "3")
global Opt_Right    := IniRead(INI_FILE, "Options", "RightClickClose", "0")
global Opt_HideIcon := IniRead(INI_FILE, "Options", "HideTrayIcon", "0")
global Cur_Lang     := IniRead(INI_FILE, "System", "Language", "EN")

; ========================================================
; Language Data
; ========================================================
global LangData := Map(
    "ZH", Map(
        "Title",      "浏览器标签增强脚本",
        "Double",     "双击关闭标签页",
        "Scroll",     "滚轮切换标签页",
        "Right",      "右键关闭标签页",
        "HideIcon",   "显示/隐藏托盘图标 (Ctrl+Alt+H)",
        "Startup",    "开机自动启动",
        "SwitchLang", "Switch to English",
        "Exit",       "退出",
        "Reload",     "重启脚本",
        "OptOff",     "关闭",
        "OptChrome",  "仅 Chrome 生效",
        "OptEdge",    "仅 Edge 生效",
        "OptBoth",    "两者均生效"
    ),
    "EN", Map(
        "Title",      "Browser Tab Enhancer",
        "Double",     "Double-Click to Close Tab",
        "Scroll",     "Scroll to Switch Tabs",
        "Right",      "Right-Click to Close Tab",
        "HideIcon",   "Toggle Tray Icon (Ctrl+Alt+H)",
        "Startup",    "Run at Startup",
        "SwitchLang", "切换到中文",
        "Exit",       "Exit",
        "Reload",     "Reload Script",
        "OptOff",     "Off",
        "OptChrome",  "Chrome Only",
        "OptEdge",    "Edge Only",
        "OptBoth",    "Both Active"
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

    opts := Map("0", T["OptOff"], "1", T["OptChrome"], "2", T["OptEdge"], "3", T["OptBoth"])

    ; --- Double Click Submenu ---
    MenuDouble := Menu()
    MenuDouble.Add(opts["0"], (*) => SetOption("Double", "0"))
    MenuDouble.Add(opts["1"], (*) => SetOption("Double", "1"))
    MenuDouble.Add(opts["2"], (*) => SetOption("Double", "2"))
    MenuDouble.Add(opts["3"], (*) => SetOption("Double", "3"))
    MenuDouble.Check(opts[Opt_Double])

    ; --- Scroll Submenu ---
    MenuScroll := Menu()
    MenuScroll.Add(opts["0"], (*) => SetOption("Scroll", "0"))
    MenuScroll.Add(opts["1"], (*) => SetOption("Scroll", "1"))
    MenuScroll.Add(opts["2"], (*) => SetOption("Scroll", "2"))
    MenuScroll.Add(opts["3"], (*) => SetOption("Scroll", "3"))
    MenuScroll.Check(opts[Opt_Scroll])

    ; --- Right Click Submenu ---
    MenuRight := Menu()
    MenuRight.Add(opts["0"], (*) => SetOption("Right", "0"))
    MenuRight.Add(opts["1"], (*) => SetOption("Right", "1"))
    MenuRight.Add(opts["2"], (*) => SetOption("Right", "2"))
    MenuRight.Add(opts["3"], (*) => SetOption("Right", "3"))
    MenuRight.Check(opts[Opt_Right])

    A_TrayMenu.Add(T["Double"], MenuDouble)
    A_TrayMenu.Add(T["Scroll"], MenuScroll)
    A_TrayMenu.Add(T["Right"], MenuRight)
    A_TrayMenu.Add()
    A_TrayMenu.Add(T["Startup"], ToggleStartup)
    A_TrayMenu.Add(T["HideIcon"], ToggleTrayIconState)
    A_TrayMenu.Add(T["SwitchLang"], ToggleLanguage)
    A_TrayMenu.Add()
    A_TrayMenu.Add(T["Reload"], (*) => Reload())
    A_TrayMenu.Add(T["Exit"], (*) => ExitApp())

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
SetOption(feature, val) {
    global Opt_Double, Opt_Scroll, Opt_Right
    if (feature == "Double") {
        Opt_Double := val
        IniWrite(val, INI_FILE, "Options", "DoubleClickClose")
    } else if (feature == "Scroll") {
        Opt_Scroll := val
        IniWrite(val, INI_FILE, "Options", "ScrollSwitchTab")
    } else if (feature == "Right") {
        Opt_Right := val
        IniWrite(val, INI_FILE, "Options", "RightClickClose")
    }
    BuildMenu()
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

IsTargetBrowser(optValue) {
    if (optValue == "0")
        return false

    try {
        exeName := WinGetProcessName("A")
        if (optValue == "1" && exeName == "chrome.exe")
            return true
        if (optValue == "2" && exeName == "msedge.exe")
            return true
        if (optValue == "3" && (exeName == "chrome.exe" || exeName == "msedge.exe"))
            return true
    }
    return false
}

; ========================================================
; Browser Context Hotkeys
; ========================================================
#HotIf WinActive("ahk_exe chrome.exe") || WinActive("ahk_exe msedge.exe")

; --- Double-Click Tab Close ---
~LButton::
{
    if !IsTargetBrowser(Opt_Double)
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
    if !IsTargetBrowser(Opt_Scroll) {
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
    if (IsTargetBrowser(Opt_Right) && IsOverTabBar()) {
        Send("{MButton}")
        return
    }
    Send("{RButton Down}")
    KeyWait("RButton")
    Send("{RButton Up}")
}
#HotIf