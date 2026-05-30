#Requires Autohotkey v2
#Warn
#SingleInstance ignore

Persistent
KeyHistory(0)
ListLines(false)
SetWorkingDir(A_ScriptDir)
TraySetIcon('C:\Users\ToYu\Pictures\icons\Fluent\png\recentmenu.png')

scripts := Map(
    A_ScriptDir '\hotif.ahk',    true,
    A_ScriptDir '\taphold.ahk',  true,
    A_ScriptDir '\arrows.ahk',   true,
    A_ScriptDir '\chars.ahk',    true,
    A_ScriptDir '\mouse.ahk',    true,
    'C:\Configs and settings\AutoHotKey\Radify\Radify Menus.ahk', true,
    'C:\Configs and settings\AutoHotKey\LanguageIndicator\language-indicator.ahk', true,
    'C:\Configs and settings\AutoHotKey\QuickSwitch\QuickSwitch.ahk', false, 
)

ShowAgain(*) {  
    static X, Y
    static pos := MouseGetPos(&X, &Y)
    
    global m
    m.Show(X, Y)
}

CreateMenu(_scripts := Scripts) {
    _m := Menu()
    _m.Add('Run',   RunScripts.Bind(_scripts))
    _m.Add('Close', CloseScripts.Bind(_scripts))
    _m.Add('Exit',  (*) => ExitApp())
    _m.Add()
    
    for script, state in _scripts {
        name := GetShortName(script)
        
        _m.Add(name, Toggle.Bind(script))
        if state 
            _m.Check(name) 
    }
    
    return _m
}

GetShortName(path, offset := 2) => '.' SubStr(path, InStr(path, '\',, -1, -offset))

Toggle(script, item, pos, m) {
    if GetKeyState('LShift') {
        CloseScripts(Map(script, true))
    } else if GetKeyState('LCtrl') {
        RunScripts(Map(script, true))
    } else {
        Scripts[script] ^= 1
        m.ToggleCheck(item)
    }
    
    ShowAgain()
}

RunScripts(_scripts, *) {
    errors := ''
    for script, state in _scripts {
        if state
            Run(script,, 'hide')
    }
    
    ExitApp()
}

CloseScripts(_scripts, *) {
    errors := ''
    for script, state in _scripts {
        if state && RunWait('taskkill /fi "WINDOWTITLE eq ' script '*',, 'hide')
            errors .= script . A_Space
    }
    
    if errors
        MsgBox('Failed to close:`n' errors, A_ScriptName ' error', 'Iconx')
        
    ExitApp()
}

MsgWarn(msg, *) {
    MsgBox(msg, A_ScriptName, 'Icon!')
}

ParseCommandLine() {
    ParseArgs:
    while A_Args.length {
        NextArg() {
            if !A_Args.Length
                ExitApp()

            return StrSplit(A_Args.RemoveAt(1), '=')
        }
            
        pair := NextArg()
        arg  := Trim(pair[1], "/-`t`"`' ")
        
        switch arg, false {  ; case-insensitive comparison    
        case 'autorun':
            RunScripts(Scripts)    
        case 'autoclose':
            CloseScripts(Scripts)
        default:
            MsgWarn('Parameter error: Unknown parameter "' arg '"')            
        }
    }
}

if (A_Args.length) {
    ParseCommandLine()
    ExitApp()
} else {
    m := CreateMenu()
    ShowAgain()
    
    $^+s::ShowAgain()
    $^+d::ExitApp
}