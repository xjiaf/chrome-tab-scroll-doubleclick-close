#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off

; ========================================================
; Initialization & Configuration
; ========================================================
SetWorkingDir(A_ScriptDir)
global INI_FILE := "settings.ini"
global STARTUP_LNK := A_Startup . "\ChromeTabEnhancer.lnk"
global OrigFocusHwnd := 0

; Initialize default settings if INI file is missing
if !FileExist(INI_FILE) {
    IniWrite("3", INI_FILE, "Options", "DoubleClickClose")
    IniWrite("3", INI_FILE, "Options", "ScrollSwitchTab")
    IniWrite("0", INI_FILE, "Options", "RightClickClose")
    IniWrite("0", INI_FILE, "Options", "HideTrayIcon")
    IniWrite("EN", INI_FILE, "System", "Language")
}

; Load settings
global Opt_Double   := IniRead(INI_FILE, "Options", "DoubleClickClose", "3")
global Opt_Scroll   := IniRead(INI_FILE, "Options", "ScrollSwitchTab", "3")
global Opt_Right    := IniRead(INI_FILE, "Options", "RightClickClose", "0")
global Opt_HideIcon := IniRead(INI_FILE, "Options", "HideTrayIcon", "0")
global Cur_Lang     := IniRead(INI_FILE, "System", "Language", "EN")

; ========================================================
; Language & UI Data
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
; Tray Menu Management
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

if (Opt_HideIcon == "1") {
    A_IconHidden := true
} else {
    UpdateTrayTip()
    BuildMenu()
}

; Global Hotkey to toggle tray icon visibility
^!h::ToggleTrayIconState()

BuildMenu() {
    A_TrayMenu.Delete()
    T := LangData[Cur_Lang]
    opts := Map("0", T["OptOff"], "1", T["OptChrome"], "2", T["OptEdge"], "3", T["OptBoth"])

    MenuDouble := Menu()
    MenuDouble.Add(opts["0"], (*) => SetOption("Double", "0"))
    MenuDouble.Add(opts["1"], (*) => SetOption("Double", "1"))
    MenuDouble.Add(opts["2"], (*) => SetOption("Double", "2"))
    MenuDouble.Add(opts["3"], (*) => SetOption("Double", "3"))
    MenuDouble.Check(opts[Opt_Double])

    MenuScroll := Menu()
    MenuScroll.Add(opts["0"], (*) => SetOption("Scroll", "0"))
    MenuScroll.Add(opts["1"], (*) => SetOption("Scroll", "1"))
    MenuScroll.Add(opts["2"], (*) => SetOption("Scroll", "2"))
    MenuScroll.Add(opts["3"], (*) => SetOption("Scroll", "3"))
    MenuScroll.Check(opts[Opt_Scroll])

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
; Core Helper Functions
; ========================================================

; Restores focus to the original window after a background scroll operation
RestoreFocusTask() {
    global OrigFocusHwnd
    if (OrigFocusHwnd) {
        if WinExist("ahk_id " OrigFocusHwnd)
            WinActivate("ahk_id " OrigFocusHwnd)
        OrigFocusHwnd := 0
    }
}

; Determines if the cursor is hovering over the browser's tab bar (DPI-aware)
IsHoveringTabBar(&hoveredHwnd := 0) {
    MouseGetPos(,, &hWnd)
    hoveredHwnd := hWnd

    try {
        minMax := WinGetMinMax("ahk_id " hWnd)
        exeName := WinGetProcessName("ahk_id " hWnd)

        CoordMode("Mouse", "Screen")
        MouseGetPos(, &screenY)
        WinGetPos(, &winY, , , "ahk_id " hWnd)
        CoordMode("Mouse", "Window")

        yPos := screenY - winY
        dpiScale := A_ScreenDPI / 96

        ; Browser-specific tab bar height definitions (at 100% scale)
        if (exeName = "chrome.exe") {
            maxHeight := 46
            winHeight := 38
        } else if (exeName = "msedge.exe") {
            maxHeight := 48
            winHeight := 42
        } else {
            maxHeight := 46
            winHeight := 40
        }

        if (minMax = 1) ; Maximized
            return (yPos >= 0 && yPos <= (maxHeight * dpiScale))
        else if (minMax = 0) ; Windowed
            return (yPos >= 0 && yPos <= (winHeight * dpiScale))
    }
    return false
}

; Checks if the target window matches the user's browser preferences
IsTargetBrowser(optValue, hWnd) {
    if (optValue == "0")
        return false
    try {
        exeName := WinGetProcessName("ahk_id " hWnd)
        if (optValue == "1" && exeName == "chrome.exe")
            return true
        if (optValue == "2" && exeName == "msedge.exe")
            return true
        if (optValue == "3" && (exeName == "chrome.exe" || exeName == "msedge.exe"))
            return true
    }
    return false
}

; Validates if the current hover state allows for tab actions
CanTriggerTabAction() {
    if !IsHoveringTabBar(&hWnd)
        return false
    return IsTargetBrowser("3", hWnd)
}

; ========================================================
; Browser Tab Enhancer Hotkeys
; ========================================================
#HotIf CanTriggerTabAction()

; --------------------------------------------------------
; Feature: Double-Click to Close Tab
; --------------------------------------------------------
~LButton::
{
    static LastClickTime := 0
    static LastWinX := 0, LastWinY := 0, LastWinW := 0, LastWinH := 0
    static LastTitle := ""

    IsHoveringTabBar(&hWnd)
    if !IsTargetBrowser(Opt_Double, hWnd)
        return

    ; Detect Double-Click (400ms threshold)
    if (A_TickCount - LastClickTime < 400) {
        LastClickTime := 0

        ; Wait for physical button release to bypass browser misclick prevention
        KeyWait("LButton", "T0.3")

        try {
            Sleep(80) ; Allow Windows OS time to process native double-click events

            if !WinExist("ahk_id " hWnd)
                return

            WinGetPos(&curX, &curY, &curW, &curH, "ahk_id " hWnd)
            curTitle := WinGetTitle("ahk_id " hWnd)

            ; Intercept action if the window shape/position changed (e.g., Maximized)
            if (LastWinX != curX || LastWinY != curY || LastWinW != curW || LastWinH != curH)
                return

            ; Intercept action if the tab title changed (e.g., clicking '+' or closing multiple tabs)
            if (LastTitle != curTitle)
                return

            ; Send MButton to natively close the target tab
            Send("{MButton}")
        }
    } else {
        ; Register First-Click metrics
        LastClickTime := A_TickCount
        try {
            WinGetPos(&LastWinX, &LastWinY, &LastWinW, &LastWinH, "ahk_id " hWnd)
            LastTitle := WinGetTitle("ahk_id " hWnd)
        }
    }
}

; --------------------------------------------------------
; Feature: Scroll to Switch Tabs (Active & Background Support)
; --------------------------------------------------------
#MaxThreadsPerHotkey 5 ; Enable concurrent thread processing for rapid scroll ticks
WheelUp::
WheelDown::
{
    IsHoveringTabBar(&hWnd)
    global OrigFocusHwnd

    if !IsTargetBrowser(Opt_Scroll, hWnd) {
        Send("{Blind}{" A_ThisHotkey "}")
        return
    }

    keyToSend := (A_ThisHotkey = "WheelDown") ? "^{PgDn}" : "^{PgUp}"

    if WinActive("ahk_id " hWnd) {
        ; Scenario: Browser is already the active window
        Send(keyToSend)
        if (OrigFocusHwnd)
            SetTimer RestoreFocusTask, -400

    } else if (OrigFocusHwnd) {
        ; Scenario: Rapid consecutive scrolling in the background
        WinActivate("ahk_id " hWnd)
        Send(keyToSend)
        SetTimer RestoreFocusTask, -400

    } else {
        ; Scenario: First scroll action initiated in the background
        curActive := WinGetID("A")
        if (curActive != hWnd) {
            OrigFocusHwnd := curActive
        }

        WinActivate("ahk_id " hWnd)
        if !WinActive("ahk_id " hWnd)
            WinWaitActive("ahk_id " hWnd, , 0.15)

        Send(keyToSend)
        SetTimer RestoreFocusTask, -400
    }
}
#MaxThreadsPerHotkey 1

; --------------------------------------------------------
; Feature: Right-Click to Close Tab
; --------------------------------------------------------
RButton::
{
    IsHoveringTabBar(&hWnd)

    if IsTargetBrowser(Opt_Right, hWnd) {
        ; MButton implicitly closes a background tab without stealing window focus
        Send("{MButton}")
        return
    }

    ; Default Right-Click fallback
    Send("{RButton Down}")
    KeyWait("RButton")
    Send("{RButton Up}")
}
#HotIf