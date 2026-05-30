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

;── Config ───────────────────────────────────────────────────────────────────────────────────────────────────────────

ExpandVariables(path) {
    ; Performs a dereference of all built-in, declared and env. variables
    ; Returns the path without variables
    pos  := 0
    
    while (pos := RegExMatch(path, "%(\w+)%", &match, ++pos)) {
        var := match[1]
        if Vars.Has(var) {
            path := StrReplace(path, "%" var "%", Vars[var])
        } else if IsSet(%var%) {
            path := StrReplace(path, "%" var "%", %var%)
        } else if EnvGet(var) {
            path := StrReplace(path, "%" var "%", EnvGet(var))
        } else {
            Err('Unassigned variable: %' var '%.`nPath: "' path '"', 'Variable')
            ExitApp(3)
        }
    }
    
    return path
}

ReadVariables() {
    if !FileExist(INI)
        return

    loop parse IniRead(INI, 'variables'), '`n' {
        data := StrSplit(A_LoopField, '=')
        Vars.Set(data[1], data[2])
    }
}

ReadScripts() {
    if !FileExist(INI)
        return

    loop parse IniRead(INI, 'scripts'), '`n' {
        data := StrSplit(A_LoopField, '=')
        Scripts.Set(ExpandVariables(data[1]), data[2])
    }
}

MapWrite(pairsMap, section := 'variables') {
    for var, value in pairsMap {
        if (value = '' || value = 'unset')
            IniDelete(INI, section, var)
        else
            IniWrite(value, INI, section, var)
    }
}

MapClean(pairsMap, section := 'variables') {
    IniDelete(INI, section)
    pairsMap.Clear()
}

Map.prototype.DefineProp('Clean', {call: MapClean})
Map.prototype.DefineProp('Write', {call: MapWrite})


;── Output ───────────────────────────────────────────────────────────────────────────────────────────────────────────

Message(msg) {
    try {
        FileAppend(msg '`n', '*')
    } catch {
        MsgBox(msg, A_ScriptName)
    }
}

Verbose(msg) {
    if IsVerbose
        try FileAppend(msg '`n', '*')
}

Warning(msg, what := A_ScriptName) {
    try {
        FileAppend(what ' warning - ' msg '`n', '**')
    } catch {
        MsgBox(msg, what ' warning', 'Icon!')
    }
}

Err(msg, what := A_ScriptName) {
    try {
        FileAppend(what ' error - ' msg '`n', '**')
    } catch {
        MsgBox(msg, what ' error', 'Iconx')
    }
}

OnError(Exception)
Exception(ex, *) {
    Err(ex.message '`n' ex.extra, ex.what)
    ExitApp(12)
}


MapToString(m) {
    str := ''
    for k, v in m {
        str .= '`n' k ' = ' v 
    }
    
    return LTrim(str, '`n')
}

Map.prototype.DefineProp('ToString', {call: MapToString})

;── Command line ─────────────────────────────────────────────────────────────────────────────────────────────────────

ParseScripts(scriptsList, separator := ';', state := true) {
    _scripts := Map()
    if !(scriptsList && separator)
        return _scripts
    
    ParseArgScripts:
    for script in StrSplit(scriptsList, separator) {
        script := ExpandVariables(script)
        
        if FileExist(script) {
            Verbose('Found "' script '"')
            _scripts.Set(script, state)
            continue("ParseArgScripts")
        }
        
        SearchScript:
        for path in Scripts {
            if InStr(GetShortName(path, 1), script) {
                Verbose('"' script '" found in storage: "' path '"')
                _scripts.Set(path, state)
                continue("ParseArgScripts")
            }
        }
        
        Warning(script, 'Script not found')
    } 
    
    return _scripts
}

ParseFile(path, separator := ';', state := true) {
    if !FileExist(path) {
        Warning(path, 'File not found')
        return Map()
    } 
    
    Verbose('Get scripts from "' path '"')
    lines := StrReplace(FileRead(path), '`n', separator)
    return ParseScripts(lines, separator, state)
}

ParseCommandLine() {
    global IsVerbose

    ParseArgs:
    while A_Args.length {
        NextArg() {
            if !A_Args.Length
                ExitApp()

            return StrSplit(A_Args.RemoveAt(1), '=')
        }
            
        pair  := NextArg()
        arg   := pair[1]
        
        GetValue() {
            if pair.Has(2)
                return Trim(pair[2], '"`'`t ')
                
            Err('Missing value for "' arg '"', 'Parameter')
            ExitApp(2)
        }
        
        GetScripts(state := true) {
            path := ExpandVariables(GetValue())

            if (SubStr(path, 1, 1) = '@') {
                path := SubStr(path, 2)  ; omit @
                return ParseFile(path, Vars['scriptsSep'], state)
            } else {
                return ParseScripts(path, Vars['scriptsSep'], state)
            }
        }
        
        switch arg, false {  ; case-insensitive comparison    
        case '-autorun':
            RunScripts(Scripts)    
        case '-autoclose':
            CloseScripts(Scripts)
            
        case '--sep':
            Vars['scriptsSep'] := GetValue() 
            Verbose('Set separator: ' GetValue())
            
        case '--run', '--close':
            _scripts := GetScripts()
            if !_scripts.count
                continue("ParseArgs")
            
            switch arg, false {
            case '--run':
                RunScripts(_scripts)
            case '--close':
                CloseScripts(_scripts)
            }   
                    
        case '--add', '--remove':        
            _scripts := GetScripts()            
            if !_scripts.count
                continue("ParseArgs")

            switch arg, false {
            case '--add':
                for script, state in _scripts {
                    Scripts.Set(script, true)
                    Verbose('Add "' script '"')
                }
            case '--remove':
                for script, state in _scripts {
                    if !Scripts.Has(script) {
                        Warning('Cannot remove non-saved script: "' script '"', 'Script')
                        continue("ParseArgs")
                    }
                    
                    Scripts.Set(script, 'unset')
                    Verbose('Remove "' script '"')
                }
            } 
        
        case '-scripts':
            Message(Scripts.ToString())
        case '-scripts-clear':
            Scripts.Clean('scripts')
            
        case '-verbose':
            IsVerbose := true   
            
        default:
            Warning('Parameter error: Unknown parameter "' arg '"')            
        }
    }
    
    Vars.Write('variables')
    Scripts.Write('scripts')
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