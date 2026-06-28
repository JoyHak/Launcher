GetShortName(path, offset := 2) {
    if (
        pos := InStr(path, '\',, -1, -offset)
     || pos := InStr(path, '/',, -1, -offset)
    ) {
        return SubStr(path, pos + 1)
    }
    
    return path
}

({}.DefineProp)(String.prototype, 'ShortName', {call: GetShortName})

RunScripts(scriptsMap, *) {
    if !scriptsMap.count
        return

    errors := ''
    for script, state in scriptsMap {
        if (state = 'enabled') {
            Run(script)
            Verbose('Run "' script '"')
        } else {
            Verbose('Cannot run disabled "' script '"')
        }
    }
}

CloseScripts(scriptsMap, *) {
    if !scriptsMap.count
        return

    errors := ''
    for script, state in scriptsMap {
        processQuery := 
        (Join`s
           "select processId, commandLine 
            from Win32_Process 
            where CommandLine like '%" script.ShortName(1) "%'"
        )

        for p in ComObjGet("winmgmts:").ExecQuery(processQuery) {
            if (p.commandLine.Find(script)) {
                ProcessClose(p.processId)
                Verbose('Close "' script '"')
                continue
            }
        }
    
        if !RunWait('taskkill /fi "WINDOWTITLE eq ' script '*',, 'hide')
            Verbose('Close "' script '"')
        else
            errors .= script . A_Space
    }
    
    if errors
        Err(errors, 'Close scripts')
}

CreateScriptsGroup() {
    static group := 'Scripts'
    
    for script in Scripts {
        if script.ShortName(1).find('.exe', -1)
            GroupAdd(group, 'ahk_exe ' script)
        else
            GroupAdd(group, script)    
    }  
    
    return group
}

GetRunningScripts() {
    _DetectHiddenWindows := A_DetectHiddenWindows
    DetectHiddenWindows(true)
    
    static group := CreateScriptsGroup()
    _windows  := WinGetList('ahk_group ' group)
    (_scripts := Map()).capacity := _windows.capacity
    
    for hwnd in _windows {
        title := WinGetTitle(hwnd)
        if title.Find('.ahk')
            path := RegExReplace(title, " - AutoHotkey v[\.\d]+$")
        else
            path := WinGetProcessPath(hwnd)

        if path
            _scripts.Set(path, 'running')
    }
  
    DetectHiddenWindows(_DetectHiddenWindows) 
    return _scripts
}