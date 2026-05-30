#Requires Autohotkey v2
#Warn
#ErrorStdOut
#Warn All, StdOut
#SingleInstance ignore
;@Ahk2Exe-ConsoleApp

Persistent()
KeyHistory(0)
ListLines(false)
SetWorkingDir(A_ScriptDir)

INI := 'launcher.ini'
IsVerbose := false

Scripts := Map()
Vars := Map('scriptsSep', ';')

;── Menu ─────────────────────────────────────────────────────────────────────────────────────────────────────────────

ShowAgain(*) {  
    static X, Y
    static pos := MouseGetPos(&X, &Y)
    
    mainMenu.Show(X, Y)
}

CreateMenu(scriptsMap := Scripts) {
    _menu := Menu()
    _menu.Add('Run',   RunScripts.Bind(scriptsMap))
    _menu.Add('Close', CloseScripts.Bind(scriptsMap))
    _menu.Add('Exit',  (*) => ExitApp())
    _menu.Add()
    
    for script, state in scriptsMap {
        name := GetShortName(script)
        
        _menu.Add(name, Select.Bind(script))
        if state 
            _menu.Check(name) 
    }
    
    return _menu
}

Select(script, item, pos, mainMenu) {
    if GetKeyState('LShift') {
        CloseScripts(Map(script, true))
    } else if GetKeyState('LCtrl') {
        RunScripts(Map(script, true))
    } else {
        Scripts[script] ^= 1
        mainMenu.ToggleCheck(item)
    }
    
    ShowAgain()
}

;── Core ─────────────────────────────────────────────────────────────────────────────────────────────────────────────

GetShortName(path, offset := 2) => '.' SubStr(path, InStr(path, '\',, -1, -offset))

RunScripts(scriptsMap, fromMenu?, *) {
    errors := ''
    for script, state in scriptsMap {
        if state {
            Run(script,, 'hide')
            Verbose('Run "' script '"')
        }
    }
    
    if IsSet(fromMenu)
        SetTimer(() => ExitApp(), -20000)
}

CloseScripts(scriptsMap, fromMenu?, *) {
    errors := ''
    for script, state in scriptsMap {
        if state && RunWait('taskkill /fi "WINDOWTITLE eq ' script '*',, 'hide')
            errors .= script . A_Space
        else
            Verbose('Close "' script '"')
    }
    
    if errors
        Err(errors, 'Close scripts')
        
    if IsSet(fromMenu)
        SetTimer(() => ExitApp(), -20000)    
}

;── Command line ─────────────────────────────────────────────────────────────────────────────────────────────────────

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
        case 'run', 'close':
            _scripts := Map()
            if pair.Has(2) {
                ParseArgScripts:
                for script in StrSplit(pair[2], ';') {
                    if FileExist(script) {
                        _scripts.Set(script, true)
                        continue("ParseArgScripts")
                    }
                    
                    SearchScript:
                    for path in Scripts {
                        if InStr(path, script) {
                            _scripts.Set(path, true)
                            continue("ParseArgScripts")
                        }
                    }
                    
                    MsgWarn('Value error: Script "' script '" not found')
                }   
            }
            
            if !_scripts.count {
                MsgWarn('Parameter error: Missing scripts for "' arg '"')
                continue
            }
            
            switch arg, false {
            case 'run':
                RunScripts(_scripts)
            case 'close':
                CloseScripts(_scripts)
            }   
            
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