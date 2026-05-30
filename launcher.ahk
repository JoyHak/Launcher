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
    scripts[script] ^= 1
    m.ToggleCheck(item)
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