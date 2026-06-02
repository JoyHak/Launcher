#Requires Autohotkey v2
#Warn

;@Ahk2Exe-SetMainIcon Icons\clock.ico
;@Ahk2Exe-SetCopyright Rafaello
;@Ahk2Exe-SetDescription https://github.com/JoyHak/Launcher
;@Ahk2Exe-SetLegalTrademarks MIT license

ShowHelpMessage(*) {
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
      --add      add script(s)
      --enable   enable script(s) or
                 add script(s) and enable
                 
      --disable  disable script(s) or
                 add script(s) and disable
      
      --run      run enabled script(s)
      --close    close running script(s)
      --remove   remove saved script(s)
      
      --sep      set separator between scripts

    Switches:
      -autorun         run all enabled scripts
      -autoclose       close all running scripts
      
      -vars            show saved variables
      -scripts         show saved scripts
      -vars-clear      clear saved variables
      -scripts-clear   clear saved scripts
      
      -save            write all data to the drive.
                       <gray>Typically data is written to disk after all params
                       parameters have been processed to reduce disk usage.</gray>
                   
      -restore         restore all data from the drive.
                       <gray>If -save was passed, restores previous version. 
                       Otherwise updates the data in memory from disk.</gray>
      
      -verbose         show additional messages
      -help, -h, -?    show this help message
      
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

    synopsis := synopsis
      .Color('[\-]+[\-\w]+', 'cyan')
      
    examples := examples
      .Color('(mainDir|AhkDir)(?=\=)', 'cyan')
      .Color('%[^%]+%',                'blue')
      .Color('@(file|list\.ini)',      'yellow')
    
    Message(usage . synopsis . examples)
}


KeyHistory(0)
ListLines(false)
SetWorkingDir(A_ScriptDir)

try TraySetIcon('Icons\clock.ico')

INI       := 'launcher.ini'
IsVerbose := false
IsConsole := false
; IsConsole := DllCall('AllocConsole')
Scripts   := Map()
Vars      := Map('scriptsSep', ';')


#include <prototypes>
#include <config>
#include <output>
#include <core>
#include <gui>
#include <commandLine>


ReadAll()

if (A_Args.length) {
    ParseCommandLine()
    WriteAndExit()
} else {
    ScriptManager()
    
    ; Hotkey('$^+s', (*) => ScriptManager())
    Hotkey('$^+s', (*) => Reload())
    Hotkey('$^+d', (*) => ExitApp())
}