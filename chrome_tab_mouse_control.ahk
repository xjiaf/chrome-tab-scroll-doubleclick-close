#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off

; ========================================================
; Initialization
; ========================================================
SetWorkingDir(A_ScriptDir)
global INI_FILE := "settings.ini"
global STARTUP_LNK := A_Startup . "\ChromeTabEnhancer.lnk"

global OrigFocusHwnd := 0

; Create default config if missing
if !FileExist(INI_FILE) {
    IniWrite("3", INI_FILE, "Options", "DoubleClickClose")
    IniWrite("3", INI_FILE, "Options", "ScrollSwitchTab")
    IniWrite("0", INI_FILE, "Options", "RightClickClose")
    IniWrite("0", INI_FILE, "Options", "HideTrayIcon")

    IniWrite("1", INI_FILE, "Layout", "Chrome")
    IniWrite("1", INI_FILE, "Layout", "Edge")

    IniWrite("ZH", INI_FILE, "System", "Language")
}

; Read Settings
global Opt_Double       := IniRead(INI_FILE, "Options", "DoubleClickClose", "3")
global Opt_Scroll       := IniRead(INI_FILE, "Options", "ScrollSwitchTab", "3")
global Opt_Right        := IniRead(INI_FILE, "Options", "RightClickClose", "0")
global Opt_HideIcon     := IniRead(INI_FILE, "Options", "HideTrayIcon", "0")

global Opt_ChromeLayout := IniRead(INI_FILE, "Layout", "Chrome", "1")
global Opt_EdgeLayout   := IniRead(INI_FILE, "Layout", "Edge", "1")
global Cur_Lang         := IniRead(INI_FILE, "System", "Language", "ZH")

; ========================================================
; Language Data
; ========================================================
global LangData := Map(
    "ZH", Map(
        "Title",      "浏览器标签增强脚本 (双擎独立版)",
        "Double",     "双击关闭标签页",
        "Scroll",     "滚轮切换标签页",
        "Right",      "右键关闭标签页",
        "LayoutC",    "Chrome 布局设置",
        "LayoutE",    "Edge 布局设置",
        "HideIcon",   "显示/隐藏托盘图标 (Ctrl+Alt+H)",
        "Startup",    "开机自动启动",
        "SwitchLang", "Switch to English",
        "Exit",       "退出",
        "Reload",     "重启脚本",
        "OptOff",     "关闭",
        "OptChrome",  "仅 Chrome 生效",
        "OptEdge",    "仅 Edge 生效",
        "OptBoth",    "两者均生效",
        "ModeTop",    "顶部水平标签栏",
        "ModeVertN",  "左侧垂直标签栏 (窄栏/折叠状态)",
        "ModeVertW",  "左侧垂直标签栏 (宽栏/展开状态)"
    ),
    "EN", Map(
        "Title",      "Browser Tab Enhancer (Dual Engine)",
        "Double",     "Double-Click to Close Tab",
        "Scroll",     "Scroll to Switch Tabs",
        "Right",      "Right-Click to Close Tab",
        "LayoutC",    "Chrome Layout",
        "LayoutE",    "Edge Layout",
        "HideIcon",   "Toggle Tray Icon (Ctrl+Alt+H)",
        "Startup",    "Run at Startup",
        "SwitchLang", "切换到中文",
        "Exit",       "Exit",
        "Reload",     "Reload Script",
        "OptOff",     "Off",
        "OptChrome",  "Chrome Only",
        "OptEdge",    "Edge Only",
        "OptBoth",    "Both Active",
        "ModeTop",    "Top Horizontal Tabs",
        "ModeVertN",  "Left Vertical Tabs (Narrow/Collapsed)",
        "ModeVertW",  "Left Vertical Tabs (Wide/Expanded)"
    )
)

; ========================================================
; Tray Icon Management & Global Hotkeys
; ========================================================
ToggleTrayIconState(*) {
    global Opt_HideIcon
    if (A_IconHidden) {
        A_IconHidden := false, Opt_HideIcon := "0"
        UpdateTrayTip(), BuildMenu(), ToolTip("Tray Icon: Visible")
    } else {
        A_IconHidden := true, Opt_HideIcon := "1"
        ToolTip("Tray Icon: Hidden (Press Ctrl+Alt+H to show)")
    }
    IniWrite(Opt_HideIcon, INI_FILE, "Options", "HideTrayIcon")
    SetTimer () => ToolTip(), -2000
}

if (Opt_HideIcon == "1")
    A_IconHidden := true
else {
    UpdateTrayTip()
    BuildMenu()
}

^!h::ToggleTrayIconState()

; ========================================================
; Menu Construction
; ========================================================
BuildMenu() {
    A_TrayMenu.Delete()
    T := LangData[Cur_Lang]
    opts := Map("0", T["OptOff"], "1", T["OptChrome"], "2", T["OptEdge"], "3", T["OptBoth"])
    modeOpts := Map("1", T["ModeTop"], "2", T["ModeVertN"], "3", T["ModeVertW"])

    MenuDouble := Menu(), MenuScroll := Menu(), MenuRight := Menu()
    MenuChrome := Menu(), MenuEdge := Menu()

    MenuDouble.Add(opts["0"], (*) => SetOption("Double", "0"))
    MenuDouble.Add(opts["1"], (*) => SetOption("Double", "1"))
    MenuDouble.Add(opts["2"], (*) => SetOption("Double", "2"))
    MenuDouble.Add(opts["3"], (*) => SetOption("Double", "3"))
    MenuDouble.Check(opts[Opt_Double])

    MenuScroll.Add(opts["0"], (*) => SetOption("Scroll", "0"))
    MenuScroll.Add(opts["1"], (*) => SetOption("Scroll", "1"))
    MenuScroll.Add(opts["2"], (*) => SetOption("Scroll", "2"))
    MenuScroll.Add(opts["3"], (*) => SetOption("Scroll", "3"))
    MenuScroll.Check(opts[Opt_Scroll])

    MenuRight.Add(opts["0"], (*) => SetOption("Right", "0"))
    MenuRight.Add(opts["1"], (*) => SetOption("Right", "1"))
    MenuRight.Add(opts["2"], (*) => SetOption("Right", "2"))
    MenuRight.Add(opts["3"], (*) => SetOption("Right", "3"))
    MenuRight.Check(opts[Opt_Right])

    MenuChrome.Add(modeOpts["1"], (*) => SetOption("ChromeLayout", "1"))
    MenuChrome.Add(modeOpts["2"], (*) => SetOption("ChromeLayout", "2"))
    MenuChrome.Add(modeOpts["3"], (*) => SetOption("ChromeLayout", "3"))
    MenuChrome.Check(modeOpts[Opt_ChromeLayout])

    MenuEdge.Add(modeOpts["1"], (*) => SetOption("EdgeLayout", "1"))
    MenuEdge.Add(modeOpts["2"], (*) => SetOption("EdgeLayout", "2"))
    MenuEdge.Add(modeOpts["3"], (*) => SetOption("EdgeLayout", "3"))
    MenuEdge.Check(modeOpts[Opt_EdgeLayout])

    A_TrayMenu.Add(T["Double"], MenuDouble)
    A_TrayMenu.Add(T["Scroll"], MenuScroll)
    A_TrayMenu.Add(T["Right"], MenuRight)
    A_TrayMenu.Add()
    A_TrayMenu.Add(T["LayoutC"], MenuChrome)
    A_TrayMenu.Add(T["LayoutE"], MenuEdge)
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
    global Opt_Double, Opt_Scroll, Opt_Right, Opt_ChromeLayout, Opt_EdgeLayout
    if (feature == "Double")
        Opt_Double := val, IniWrite(val, INI_FILE, "Options", "DoubleClickClose")
    else if (feature == "Scroll")
        Opt_Scroll := val, IniWrite(val, INI_FILE, "Options", "ScrollSwitchTab")
    else if (feature == "Right")
        Opt_Right := val, IniWrite(val, INI_FILE, "Options", "RightClickClose")
    else if (feature == "ChromeLayout")
        Opt_ChromeLayout := val, IniWrite(val, INI_FILE, "Layout", "Chrome")
    else if (feature == "EdgeLayout")
        Opt_EdgeLayout := val, IniWrite(val, INI_FILE, "Layout", "Edge")
    BuildMenu()
}

ToggleLanguage(*) {
    global Cur_Lang := (Cur_Lang = "ZH" ? "EN" : "ZH")
    IniWrite(Cur_Lang, INI_FILE, "System", "Language")
    UpdateTrayTip(), BuildMenu()
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
RestoreFocusTask() {
    global OrigFocusHwnd
    if (OrigFocusHwnd) {
        if WinExist("ahk_id " OrigFocusHwnd)
            WinActivate("ahk_id " OrigFocusHwnd)
        OrigFocusHwnd := 0
    }
}

IsHoveringTabBar(&hoveredHwnd) {
    MouseGetPos(,, &hWnd)
    hoveredHwnd := hWnd

    try {
        minMax := WinGetMinMax("ahk_id " hWnd)
        exeName := WinGetProcessName("ahk_id " hWnd)

        layoutMode := "0"
        if (exeName = "chrome.exe")
            layoutMode := Opt_ChromeLayout
        else if (exeName = "msedge.exe")
            layoutMode := Opt_EdgeLayout
        else
            return false

        CoordMode("Mouse", "Screen")
        MouseGetPos(&screenX, &screenY)
        WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " hWnd)
        CoordMode("Mouse", "Window")

        xPos := screenX - winX
        yPos := screenY - winY
        dpiScale := A_ScreenDPI / 96

        if (exeName = "chrome.exe")
            topSafeZone := (minMax = 1) ? 46 : 38
        else
            topSafeZone := (minMax = 1) ? 48 : 42

        if (layoutMode == "2" || layoutMode == "3") {
            if (yPos < (topSafeZone * dpiScale))
                return false

            if (layoutMode == "2")
                maxWidth := (exeName = "chrome.exe") ? 52 : 48
            else
                maxWidth := (exeName = "chrome.exe") ? 320 : 250

            return (xPos >= 0 && xPos <= (maxWidth * dpiScale))
        }

        if (layoutMode == "1") {
            return (yPos >= 0 && yPos <= (topSafeZone * dpiScale))
        }
    }
    return false
}

IsTargetBrowser(optValue, hWnd) {
    if (optValue == "0")
        return false
    try {
        exeName := WinGetProcessName("ahk_id " hWnd)
        if (optValue == "1" && exeName = "chrome.exe") || (optValue == "2" && exeName = "msedge.exe") || (optValue == "3" && (exeName = "chrome.exe" || exeName = "msedge.exe"))
            return true
    }
    return false
}

CanTriggerTabAction() {
    if !IsHoveringTabBar(&hWnd)
        return false
    return IsTargetBrowser("3", hWnd)
}

SendCloseTabClick(hWnd) {
    exeName := WinGetProcessName("ahk_id " hWnd)
    layoutMode := (exeName = "chrome.exe") ? Opt_ChromeLayout : (exeName = "msedge.exe" ? Opt_EdgeLayout : "1")

    if (layoutMode == "2" || layoutMode == "3") {
        dpiScale := A_ScreenDPI / 96
        CoordMode("Mouse", "Window")
        MouseGetPos(&mX, &mY)

        if (mX > 52 * dpiScale) {
            iconX := 24 * dpiScale
            MouseClick("Middle", iconX, mY, 1, 0)
            MouseMove(mX, mY, 0)
            return
        }
    }
    Send("{MButton}")
}

; ========================================================
; Browser Context Hotkeys
; ========================================================
#HotIf CanTriggerTabAction()

~LButton:: {
    static LastClickTime := 0
    static LastWinX := 0, LastWinY := 0, LastWinW := 0, LastWinH := 0
    static LastClickX := 0, LastClickY := 0

    IsHoveringTabBar(&hWnd)
    if !IsTargetBrowser(Opt_Double, hWnd)
        return

    CoordMode("Mouse", "Window")
    MouseGetPos(&curClickX, &curClickY)

    if (A_TickCount - LastClickTime < 400) {
        LastClickTime := 0
        KeyWait("LButton", "T0.3")

        try {
            Sleep(80)
            if !WinExist("ahk_id " hWnd)
                return
            WinGetPos(&curX, &curY, &curW, &curH, "ahk_id " hWnd)
            if (LastWinX != curX || LastWinY != curY || LastWinW != curW || LastWinH != curH)
                return

            ; Reject pseudo double-clicks that jump across tabs
            if (Abs(LastClickX - curClickX) > 40 || Abs(LastClickY - curClickY) > 30)
                return

            SendCloseTabClick(hWnd)
        }
    } else {
        LastClickTime := A_TickCount
        try WinGetPos(&LastWinX, &LastWinY, &LastWinW, &LastWinH, "ahk_id " hWnd)
        LastClickX := curClickX, LastClickY := curClickY
    }
}

#MaxThreadsPerHotkey 5
WheelUp::
WheelDown:: {
    IsHoveringTabBar(&hWnd)
    global OrigFocusHwnd

    if !IsTargetBrowser(Opt_Scroll, hWnd) {
        Send("{Blind}{" A_ThisHotkey "}")
        return
    }

    keyToSend := (A_ThisHotkey = "WheelDown") ? "^{PgDn}" : "^{PgUp}"

    if WinActive("ahk_id " hWnd) {
        Send(keyToSend)
        if (OrigFocusHwnd)
            SetTimer RestoreFocusTask, -400
    } else if (OrigFocusHwnd) {
        WinActivate("ahk_id " hWnd)
        Send(keyToSend)
        SetTimer RestoreFocusTask, -400
    } else {
        curActive := WinExist("A")
        if (curActive && curActive != hWnd)
            OrigFocusHwnd := curActive

        WinActivate("ahk_id " hWnd)
        if !WinActive("ahk_id " hWnd)
            WinWaitActive("ahk_id " hWnd, , 0.15)

        Send(keyToSend)
        SetTimer RestoreFocusTask, -400
    }
}
#MaxThreadsPerHotkey 1

RButton:: {
    IsHoveringTabBar(&hWnd)
    if IsTargetBrowser(Opt_Right, hWnd) {
        SendCloseTabClick(hWnd)
        return
    }
    Send("{RButton Down}")
    KeyWait("RButton")
    Send("{RButton Up}")
}
#HotIf