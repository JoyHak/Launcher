#Requires Autohotkey v2
#Warn
#ErrorStdOut
#Warn All, StdOut
#SingleInstance ignore

;@Ahk2Exe-SetMainIcon clock.ico
;@Ahk2Exe-SetCopyright Rafaello
;@Ahk2Exe-SetDescription https://github.com/JoyHak/Launcher
;@Ahk2Exe-SetLegalTrademarks MIT license

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


Persistent()
KeyHistory(0)
ListLines(false)
SetWorkingDir(A_ScriptDir)

try TraySetIcon('clock.ico')

INI       := 'launcher.ini'
IsVerbose := false
Scripts   := Map()
Vars      := Map('scriptsSep', ';')


#include <prototypes>
#include <config>
#include <output>
#include <core>
#include <gui>
#include <commandLine>


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