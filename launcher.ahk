#Requires Autohotkey v2
#Warn
#ErrorStdOut
#Warn All, StdOut
#SingleInstance ignore

;@Ahk2Exe-SetMainIcon clock.ico
;@Ahk2Exe-SetCopyright Rafaello
;@Ahk2Exe-SetDescription https://github.com/JoyHak/Launcher
;@Ahk2Exe-SetLegalTrademarks MIT license

Persistent()
KeyHistory(0)
ListLines(false)
SetWorkingDir(A_ScriptDir)

try TraySetIcon('clock.ico')

INI := 'launcher.ini'
IsVerbose := false

Scripts := Map()
Vars := Map('scriptsSep', ';')

ShowHelpMessage() {
    usage := 
    (
    "<gray>Launch saved scripts and applications.
    Copyright (c) 2026 Rafaello
    https://github.com/JoyHak/Launcher</gray>
    
    Usage:
      launcher --param=script1<gray>[;script2;script3...]</gray>
      launcher --param=<yellow>@file</yellow>
      launcher -switch
      launcher <cyan>variable</cyan>=value
    
"
)
    synopsis := 
    (
    "Parameters:
      --run     run script(s)
      --close   close script(s)
      --add     add script(s)
      --remove  remove script(s)
      --sep     set separator between scripts

    Switches:
      -autorun         run all script
      -autoclose       close all script
      -vars            show saved variables
      -scripts         show saved scripts
      -vars-clear      clear saved variables
      -scripts-clear   clear saved scripts
      -verbose         show additional messages
      <gray>-h, -?           show this help message</gray>

    Pass one or more scripts, separated by <green>;</green>
      launcher --run=quickswitch<green>;</green>radify

    Separator can be changed:
      launcher --sep=<green>^</green> --run=quickswitch<green>^</green>radify
      launcher --run=arrows<green>^</green>chars  separator is saved

    You can specify full path or filename only:
      launcher --run=quickswitch
      launcher --run=C:\Ahk\quickswitch
      
"
)
    examples := 
    (
    "Multiple scripts can be read from @file:
      launcher --add=@list.ini
      launcher --remove=@list.ini

      @file can be quoted full path:
        launcher --run=<yellow>@'C:\Temp files\My scripts'</yellow>
        launcher --run=<yellow>'@C:\Temp files\My scripts'</yellow>

        or path with variables:
        launcher list=C:\listfile.ini --add=@%list%

      @file may contain scripts, variables and
      strings, separated by <cyan>--sep</cyan>:
        C:\s1.ahk<green>;</green>C:\s2.ahk
        C:\%A_Temp%\s3.ahk
        C:\%myvar%\s4.ahk

      It can be passed to any parameter.
    
    <cyan>Parameters|switches</cyan> order affects events sequence:
      launcher <cyan>-autoclose</cyan> <green>--run</green>=quickswitch    close all scripts, then launch quickswitch
      launcher <green>--run</green>=quickswitch <cyan>-autoclose</cyan>    launch quickswitch, then close all scripts
      launcher <green>--add</green>=@list.ini <cyan>-autoclose</cyan>      save multiple scripts and run them
    
    Assigned <cyan>variable</cyan> will be saved:
      launcher mainDir=C:\Scripts\DarkGui
      launcher --run=%mainDir%\DarkTheme.ahk
    
      New value can contain variable too:
      launcher mainDir=%A_ScriptDir%\DarkGui
    
      Value can be changed on the fly:
        launcher AhkDir=C:\Ahk <green>--run</green>=%AhkDir%\quickswitch AhkDir=C:\Scripts <green>--run</green>=%AhkDir%\radify
      
      Variable can be removed:
        launcher AhkDir=
        launcher AhkDir=<magenta>unset</magenta>
       
      You can use AutoHotkey built-in/saved/environment variables anywhere:
        launcher --run=%A_ScriptFullPath% --run=%A_ScriptDir%\quickswitch.ahk
        launcher --close=%TEMP%\junk.ahk --run=%A_Temp%\junk.ahk
        launcher --add=%ConEmuDir%\update.py
        
      ...and include them to @file:
        C:\%A_Temp%\script.ahk     line from @list.ini
        launcher --add=@list.ini   will add 'C:\%A_Temp%\script.ahk'

"
)

    Colorize(&synopsis,    '[\-]+[\-\w]+',           'cyan')
    Colorize(&examples,    '(mainDir|AhkDir)(?=\=)', 'cyan')
    Colorize(&examples,    '%[^%]+%',                'blue')
    Colorize(&examples,    '@(file|list\.ini)',      'yellow')
    
    Message(usage . synopsis . examples)
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

GetOutputHandle() {
    static STD_INPUT_HANDLE   := -10
    static STD_OUTPUT_HANDLE  := -11
    static STD_ERROR_HANDLE   := -12

    return DllCall('GetStdHandle', 'int', STD_OUTPUT_HANDLE)     
}

FreeOutput(*) {
    hConsole := DllCall('GetConsoleWindow')
    ControlSend('{Enter}', , 'ahk_id ' hConsole)
    
    DllCall('FreeConsole')
}

AttachOutput() {
    DllCall('FreeConsole')
    DllCall('AttachConsole', 'int', -1)
    
    OnExit(FreeOutput)
}

Output(text, color := 'white') {
    static colors := Map(
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
    
    normalColor := colors.Get(color, 7)
    
    Print(msg, _color := normalColor) {
        static hConsole := GetOutputHandle()
        DllCall(
            'SetConsoleTextAttribute', 
            'ptr', hConsole, 
            'uint', _color
        )
        
        DllCall(
            'WriteConsoleW',
			'UPtr', hConsole,
			'Str',  msg,
			'UInt', StrLen(msg),
			'UInt*', 0,
			'uint',  0
        )
    }

    pos := 1
    while (pos <= StrLen(text)) {
        if (RegExMatch(text, 's)<(\w+)>(.*?)</\1>', &match, pos)) {
            ; Print normal text before the match
            normalText := SubStr(text, pos, match.pos - pos)
            if (normalText)
                Print(normalText)
            
            ; Handle nested tags
            Output(match[2], match[1])
            
            ; Move position forward
            pos := match.pos + match.len
        } else {
            ; Print remaining text
            Print(SubStr(text, pos))
            break
        }
    }
}

Message(msg, icon := '', normalColor := 'white') {
    try {
        Output(msg '`n', normalColor)
    } catch OSError as ex {
        if (ex.number != 6)
            throw ex  ; not a console issue
    
        msg := RegExReplace(msg, 's)<(\w+)>(.*?)</\1>', '$2')
        MsgBox(msg, A_ScriptName, icon)
    }
}

Verbose(msg) {
    if IsVerbose
        Message(Format('<gray>{}</gray>', msg))
}

Warning(msg, what := A_ScriptName) {
    Message(
        Format('<yellow>{} warning - {}</yellow>', what, msg), 
        'Icon!'
    )
}

Err(msg, what := A_ScriptName) {
    Message(
        Format('<red>{} error - {}</red>', what, msg), 
        'Iconx'
    )
}

OnError(Exception)
Exception(ex, *) {
    Err(ex.message '`n' ex.extra, ex.what)
    ExitApp(12)
}



Colorize(&str, regex, colorTag) {
    str := RegExReplace(
        str, 
        regex,
        Format('<{1}>$0</{1}>', colorTag)
    )
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
    AttachOutput()

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
            global IsVerbose := true
        case '-h', '-?':
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