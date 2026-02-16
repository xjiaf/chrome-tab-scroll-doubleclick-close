#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off

; ========================================================
; Initialization
; ========================================================
SetWorkingDir(A_ScriptDir)
global INI_FILE := "settings.ini"
global STARTUP_LNK := A_Startup . "\ChromeTabEnhancer.lnk"

; Store the original active window handle for background scrolling
global OrigFocusHwnd := 0

; Create default config if missing
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
^!h::ToggleTrayIconState()

; ========================================================
; Menu Construction
; ========================================================
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
; Helper Functions
; ========================================================

; Timer function: Restores focus to the originally active window
RestoreFocusTask() {
    global OrigFocusHwnd
    if (OrigFocusHwnd) {
        if WinExist("ahk_id " OrigFocusHwnd) {
            WinActivate("ahk_id " OrigFocusHwnd)
        }
        ; Always reset the handle to prevent focus deadlock
        OrigFocusHwnd := 0
    }
}

; Dynamic DPI-aware height calculation for tab bar boundaries
IsHoveringTabBar(&hoveredHwnd := 0) {
    MouseGetPos(,, &hWnd)
    hoveredHwnd := hWnd

    try {
        minMax := WinGetMinMax("ahk_id " hWnd)
        exeName := WinGetProcessName("ahk_id " hWnd)

        ; Use absolute screen coordinates for background window calculation
        CoordMode("Mouse", "Screen")
        MouseGetPos(, &screenY)
        WinGetPos(, &winY, , , "ahk_id " hWnd)
        CoordMode("Mouse", "Window")

        yPos := screenY - winY
        dpiScale := A_ScreenDPI / 96

        ; Browser-specific height tuning (base values at 100% scale)
        if (exeName = "chrome.exe") {
            maxHeight := 46
            winHeight := 38 ; Strict limit for Windowed Chrome to avoid address bar
        } else if (exeName = "msedge.exe") {
            maxHeight := 48
            winHeight := 42 ; Edge has a slightly thicker title bar area
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

; Check if hovered window matches target browser settings
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

; Verify if cursor is over a valid browser tab bar
CanTriggerTabAction() {
    if !IsHoveringTabBar(&hWnd)
        return false
    return IsTargetBrowser("3", hWnd)
}

; ========================================================
; Browser Context Hotkeys
; ========================================================
#HotIf CanTriggerTabAction()

; Double-Click Tab Close
~LButton::
{
    static LastClickTime := 0
    static LastWinX := 0, LastWinY := 0, LastWinW := 0, LastWinH := 0

    IsHoveringTabBar(&hWnd)
    if !IsTargetBrowser(Opt_Double, hWnd)
        return

    if (A_TickCount - LastClickTime < 400) {

        LastClickTime := 0

        ; Prevent sending MButton before the physical LButton is released
        KeyWait("LButton", "T0.3")

        try {
            ; Wait briefly for Windows to process native double-click actions (like resize/maximize)
            Sleep(80)

            if !WinExist("ahk_id " hWnd)
                return

            WinGetPos(&curX, &curY, &curW, &curH, "ahk_id " hWnd)

            ; Intercept if window shape/position changed (avoids triggering Autoscroll when maximizing)
            if (LastWinX != curX || LastWinY != curY || LastWinW != curW || LastWinH != curH)
                return

            ; Only send MButton if the window shape/position is completely unchanged
            Send("{MButton}")
        }

    } else {
        LastClickTime := A_TickCount

        ; Record the exact window dimensions on the first click
        try WinGetPos(&LastWinX, &LastWinY, &LastWinW, &LastWinH, "ahk_id " hWnd)
    }
}

; Scroll Switch Tabs (Multi-thread allowed to catch fast scrolling ticks)
#MaxThreadsPerHotkey 5
WheelUp::
WheelDown::
{
    IsHoveringTabBar(&hWnd)
    global OrigFocusHwnd

    if !IsTargetBrowser(Opt_Scroll, hWnd) {
        Send("{Blind}{" A_ThisHotkey "}")
        return
    }

    ; Determine keystroke to keep logic clean
    keyToSend := (A_ThisHotkey = "WheelDown") ? "^{PgDn}" : "^{PgUp}"

    if WinActive("ahk_id " hWnd) {
        ; Browser is already active
        Send(keyToSend)

        ; Refresh focus return timer if currently in a background scrolling streak
        if (OrigFocusHwnd)
            SetTimer RestoreFocusTask, -400

    } else if (OrigFocusHwnd) {
        ; Subsequent rapid scroll ticks in background: instant response
        WinActivate("ahk_id " hWnd)
        Send(keyToSend)
        SetTimer RestoreFocusTask, -400

    } else {
        ; First scroll tick in background: setup focus return and prevent self-loop
        curActive := WinGetID("A")

        ; Only record original window if it's NOT the browser itself
        if (curActive != hWnd) {
            OrigFocusHwnd := curActive
        }

        WinActivate("ahk_id " hWnd)

        ; Remove blind sleep, wait slightly only if not fully active yet
        if !WinActive("ahk_id " hWnd)
            WinWaitActive("ahk_id " hWnd, , 0.15)

        Send(keyToSend)

        ; 400ms covers human scrolling intervals, avoiding focus ping-pong
        SetTimer RestoreFocusTask, -400
    }
}
#MaxThreadsPerHotkey 1

; Right Click Close Tab
RButton::
{
    IsHoveringTabBar(&hWnd)

    if IsTargetBrowser(Opt_Right, hWnd) {
        ; Send Middle Mouse Button (closes tabs natively without stealing focus)
        Send("{MButton}")
        return
    }

    ; Fallback to normal Right Click
    Send("{RButton Down}")
    KeyWait("RButton")
    Send("{RButton Up}")
}
#HotIf