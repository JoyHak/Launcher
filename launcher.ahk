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

ShowHelpMessage() {
    Message
    (`
    "<gray>Launches pre-defined apps and scripts.
    Copyright (c) 2026 Rafaello</gray>

     Usage:
       launcher --param=script1<gray>[;script2;script3...]</gray>
       launcher --param=<yellow>@file</yellow>
       launcher -switch
       launcher <cyan>variable</cyan>=value

     Parameters:
       <cyan>--run</cyan>     run script(s)
       <cyan>--close</cyan>   close script(s)
       <cyan>--add</cyan>     add script(s)
       <cyan>--remove</cyan>  remove script(s)
       <cyan>--sep</cyan>     set separator between scripts
       <gray>--help</gray>    show this help message

     Switches:
       <cyan>-autorun</cyan>         run all script
       <cyan>-autoclose</cyan>       close all script
       <cyan>-vars</cyan>            show saved variables
       <cyan>-scripts</cyan>         show saved scripts
       <cyan>-vars-clear</cyan>      clear saved variables
       <cyan>-scripts-clear</cyan>   clear saved scripts
       <cyan>-verbose</cyan>         show additional messages
       <gray>-h, -?</gray>           show this help message

     Pass one or more scripts, separated by <green>;</green>
       launcher --run=quickswitch<green>;</green>radify

     Separator can be changed:
       launcher <cyan>--sep</cyan>=<green>^</green> --run=quickswitch<green>^</green>radify
       launcher --run=arrows<green>^</green>chars  separator is saved

     You can specify full path or filename only:
       launcher --run=quickswitch
       launcher --run=C:\Ahk\quickswitch

     Multiple scripts can be read from <yellow>@file</yellow>:
       launcher --add=<yellow>@list.ini</yellow>
       launcher --remove=<yellow>@list.ini</yellow>

       <yellow>@file</yellow> can be quoted full path:
         launcher --run=<yellow>@'C:\Temp files\My scripts'</yellow>
         launcher --run=<yellow>'@C:\Temp files\My scripts'</yellow>

         or path with variables:
         launcher list=C:\listfile.ini --add=@<blue>%list%</blue>

       <yellow>@file</yellow> may contain scripts, variables and
       strings, separated by <cyan>--sep</cyan>:
         C:\s1.ahk<green>;</green>C:\s2.ahk
         C:\<blue>%A_Temp%</blue>\s3.ahk
         C:\<blue>%myvar%</blue>\s4.ahk

       It can be passed to any parameter.

     <cyan>Parameters|switches</cyan> order affects events sequence:
       launcher <cyan>-autoclose</cyan> <green>--run</green>=quickswitch    close all scripts, then launch quickswitch
       launcher <green>--run</green>=quickswitch <cyan>-autoclose</cyan>    launch quickswitch, then close all scripts
       launcher <green>--add</green>=<yellow>@list.ini</yellow> <cyan>-autoclose</cyan>      save multiple scripts and run them

     Assigned <cyan>variable</cyan> will be saved:
       launcher <cyan>mainDir</cyan>=C:\Scripts\DarkGui
       launcher --run=<blue>%mainDir%</blue>\DarkTheme.ahk
    
       New value can contain variable too:
       launcher <cyan>mainDir</cyan>=<blue>%A_ScriptDir%</blue>\DarkGui
    
       Value can be changed on the fly:
         launcher <cyan>AhkDir</cyan>=C:\Ahk <green>--run</green>=<blue>%AhkDir%</blue>\quickswitch <cyan>AhkDir</cyan>=C:\Scripts <green>--run</green>=<blue>%AhkDir%</blue>\radify
       
       Variable can be removed:
         launcher <cyan>AhkDir</cyan>=
         launcher <cyan>AhkDir</cyan>=<magenta>unset</magenta>
        
       You can use AutoHotkey built-in/saved/environment variables anywhere:
         launcher --run=<blue>%A_ScriptFullPath%</blue> --run=<blue>%A_ScriptDir%</blue>\quickswitch.ahk
         launcher --close=<blue>%TEMP%</blue>\junk.ahk --run=<blue>%A_Temp%</blue>\junk.ahk
         launcher --add=<blue>%ConEmuDir%</blue>\update.py
         
       ...and include them to <yellow>@file</yellow>:
         C:\<blue>%A_Temp%</blue>\script.ahk     line from <yellow>@list.ini</yellow>
         launcher --add=<yellow>@list.ini</yellow>   will add 'C:\<blue>%A_Temp%</blue>\script.ahk'"
    )
}

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
    if !scriptsMap.count
        return

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
    if !scriptsMap.count
        return

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

Message(text, icon := '') {
    static colorTagsPattern := 's)<(\w+)>(.*?)</\1>'
    
    static colorMap := Map(
        'black',    0,
        'blue',     1,
        'green',    2,
        'cyan',     3,
        'red',      4,
        'magenta',  5,
        'yellow',   6,
        'white',    7,
        'gray',     8,
    )

    normalColor := colorMap['white']
    
    try {
        static hConsole := DllCall('GetStdHandle', 'int', -11)
        pos := 1
        
        while (pos <= StrLen(text)) {
            if (RegExMatch(text, colorTagsPattern, &match, pos)) {
                ; Print normal text before the match
                normalText := SubStr(text, pos, match.Pos - pos)
                if (normalText) {
                    DllCall('SetConsoleTextAttribute', 'ptr', hConsole, 'uint', normalColor)
                    FileAppend(normalText, 'CONOUT$')
                }
                
                ; Print colored text
                color := colorMap.Has(match[1]) ? colorMap[match[1]] : normalColor
                DllCall('SetConsoleTextAttribute', 'ptr', hConsole, 'uint', color)
                FileAppend(match[2], 'CONOUT$')
                
                ; Move position forward
                pos := match.Pos + match.Len
            } else {
                ; Print remaining text
                DllCall('SetConsoleTextAttribute', 'ptr', hConsole, 'uint', normalColor)
                FileAppend(SubStr(text, pos), 'CONOUT$')
                break
            }
        }
        
        ; Reset color
        DllCall('SetConsoleTextAttribute', 'ptr', hConsole, 'uint', normalColor)
        FileAppend('`n', 'CONOUT$')
    } catch {
        text := RegExReplace(text, colorTagsPattern, '$2')
        MsgBox(text, A_ScriptName, icon)
    }
}

Verbose(msg) {
    if IsVerbose
        Message(Format('<gray>{}</gray>', msg))
}

Warning(msg, what := A_ScriptName) {
    Message(Format('<yellow>{} warning - {}</yellow>', what, msg), 'Icon!')
}

Err(msg, what := A_ScriptName) {
    Message(Format('<red>{} error - {}</red>', what, msg), 'Iconx')
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
            continue ParseArgScripts
        }
        
        SearchScript:
        for path in Scripts {
            if InStr(GetShortName(path, 1), script) {
                Verbose('"' script '" found in storage: "' path '"')
                _scripts.Set(path, state)
                continue ParseArgScripts
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
    for args in A_Args {
        pair := StrSplit(args, '=')
        arg  := pair[1]
        
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
                   
        case '-vars':
            Message(Vars.ToString())           
        case '-scripts':
            Message(Scripts.ToString())
            
        case '-vars-clear':
            Vars.Clean('variables')
        case '-scripts-clear':
            Scripts.Clean('scripts')
            
        case '-verbose':
            IsVerbose := true
        case '--help', '-h', '-?':
            ShowHelpMessage()    
        case '--sep':
            Vars['scriptsSep'] := GetValue() 
            Verbose('Set separator: ' GetValue())

        case '--run':
            RunScripts(GetScripts())
        case '--close':
            CloseScripts(GetScripts())
            
        case '--add':
            for script, state in GetScripts() {
                Scripts.Set(script, true)
                Verbose('Add "' script '"')
            }
            
        case '--remove':
            for script, state in GetScripts() {
                if !Scripts.Has(script) {
                    Warning('Cannot remove non-saved script: "' script '"', 'Script')
                    continue ParseArgs
                }
                
                Scripts.Set(script, 'unset')
                Verbose('Remove "' script '"')
            }
            
        default:
            ; Try to assign variable=value
            if !pair.Has(2) {
                ; No value, not a variable
                Err('Unknown parameter "' arg '"', 'Parameter') 
                continue ParseArgs
            }
            
            value := GetValue()
            
            ; Check for removing variable
            if ((value = '' || value = 'unset')) {
                if !Vars.Has(arg) {
                    Warning('Value for ' arg ' is empty', 'Value')
                    continue ParseArgs
                }
                
                Vars[arg] := 'unset'
                Verbose('Remove ' arg '=' Vars[arg])
                continue ParseArgs
            }
            
            Vars[arg] := ExpandVariables(value)
            Verbose('Assign ' arg '=' Vars[arg])
        }
    }
}

;── Main ─────────────────────────────────────────────────────────────────────────────────────────────────────────────

ReadVariables()
ReadScripts()

if (A_Args.length) {
    ParseCommandLine()
    Vars.Write('variables')
    Scripts.Write('scripts')
    ExitApp()
} else {
    mainMenu := CreateMenu()
    ShowAgain()
    
    $^+s::ShowAgain()
    $^+d::ExitApp
}