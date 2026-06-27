#Requires Autohotkey v2
#Warn

;@Ahk2Exe-SetMainIcon Icons\clock.ico
;@Ahk2Exe-SetCopyright Rafaello
;@Ahk2Exe-SetDescription https://github.com/JoyHak/Launcher
;@Ahk2Exe-SetLegalTrademarks MIT license

PrintHelp(*) {
    usage := '
    (`
    ~Launch saved scripts and applications.
    Copyright (c) 2026 Rafaello
    https://github.com/JoyHak/Launcher~
    
    #Usage:#
      launcher --param=script1~[;script2;script3...]~
      launcher --param=@file
      launcher -switch
      launcher __variable__=value
    
)'
    synopsis := '
    (`
    #Parameters:#
      --add      add script(s)
      --enable   enable script(s) or
                 add script(s) and enable
                 
      --disable  disable script(s) or
                 add script(s) and disable
      
      --run      run enabled script(s)
      --close    close running script(s)
      --remove   remove saved script(s)
      
      --sep      set separator between scripts

    #Switches:#
      -autorun         run all enabled scripts
      -autoclose       close all running scripts
      
      -vars            show saved variables
      -scripts         show saved scripts
      -vars-clear      clear saved variables
      -scripts-clear   clear saved scripts
      
      -save            write all data to the drive.
                       ~Typically data is written to disk after all params
                       parameters have been processed to reduce disk usage.~
                   
      -restore         restore all data from the drive.
                       ~If -save was passed, restores previous version. 
                       Otherwise updates the data in memory from disk.~
      
      -verbose         show additional messages
      -help, -h, -?    show this help message
      
    Pass one or more scripts, separated by `;`
      launcher --run=quickswitch`;`radify

    Separator can be changed:
      launcher --sep=`^` --run=quickswitch`^`radify
      launcher --run=arrows`^`chars  separator is saved
      
      Special batch/powershell symbols can be escaped via quotes:
      launcher --sep='|'
      launcher --sep="|"

    You can specify full path or filename only:
      launcher --run=quickswitch
      launcher --run=C:\Ahk\quickswitch
      
)'
    examples := '
    (`
    Multiple scripts can be read from @file:
      launcher --add=@list.ini
      launcher --remove=@list.ini

      @file can be quoted full path:
        launcher --run=@"C:\Temp files\My scripts"
        launcher --run="@C:\Temp files\My scripts"

        or path with variables:
        launcher list=C:\listfile.ini --add=@%list%

      @file may contain scripts, variables and
      strings, separated by --sep:
        C:\s1.ahk`;`C:\s2.ahk
        C:\%A_Temp%\s3.ahk
        C:\%myvar%\s4.ahk

      It can be passed to any parameter.
    
    #Parameters|switches# order affects events sequence:
      launcher -autoclose --run=quickswitch    close all scripts, then launch quickswitch
      launcher --run=quickswitch -autoclose    launch quickswitch, then close all scripts
      launcher --add=@list.ini -autoclose      save multiple scripts and run them
    
    Assigned __variable__ will be saved:
      launcher mainDir=C:\Scripts\DarkGui
      launcher --run=%mainDir%\DarkTheme.ahk
    
      New value can contain variable too:
      launcher mainDir=%A_ScriptDir%\DarkGui
    
      Value can be changed on the fly:
        launcher AhkDir=C:\Ahk --run=%AhkDir%\quickswitch AhkDir=C:\Scripts --run=%AhkDir%\radify
      
      Variable can be removed:
        launcher AhkDir=
        launcher AhkDir=__unset__
       
      You can use AutoHotkey built-in/saved/environment variables anywhere:
        launcher --run=%A_ScriptFullPath% --run=%A_ScriptDir%\quickswitch.ahk
        launcher --close=%TEMP%\junk.ahk --run=%A_Temp%\junk.ahk
        launcher --add=%ConEmuDir%\update.py
        
      ...and include them to @file:
        C:\%A_Temp%\script.ahk     line from @list.ini
        launcher --add=@list.ini   will add "C:\%A_Temp%\script.ahk"

)'
    
    msg := usage . synopsis . examples

    msg := 
      msg.Color([
        '(@(file|list\.ini))',    'yellow',   ; list
        '(mainDir|AhkDir)(?=\=)', 'purple',   ; variables names
        '(%[^%]+%)',              'blue',     ; variables values
        '(\-+[\-\w]+)(?=[ =])',   'cyan',     ; switches
        '\*\*([^\*]+)\*\*',       'crimson',  
        '__([^_]+)__',            'magenta',  
        '~',                      'gray',
        '``',                     'green', 
        '#',                      'orange', 
        '"',                      'green', 
      ]).Print()
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