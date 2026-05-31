GetShortName(path, offset := 2) {
    if (
        pos := InStr(path, '\',, -1, -offset)
     || pos := InStr(path, '/',, -1, -offset)
    ) {
        return '.' SubStr(path, pos)
    }
    
    return path
}

RunScripts(scriptsMap, *) {
    if !scriptsMap.count
        return

    errors := ''
    for script, state in scriptsMap {
        if (state = 'enabled') {
            Run(script,, 'hide')
            Verbose('Run "' script '"')
        } else {
            Warning('Cannot run disabled "' script '"')
        }
    }
}

CloseScripts(scriptsMap, *) {
    if !scriptsMap.count
        return

    errors := ''
    for script, state in scriptsMap {
        if (state != 'running') {
            Warning('"' script '" already closed')
            continue
        }
        if !RunWait('taskkill /fi "WINDOWTITLE eq ' script '*',, 'hide')
            Verbose('Close "' script '"')
        else
            errors .= script . A_Space
    }
    
    if errors
        Err(errors, 'Close scripts')
}

GetRunningScripts() {
    _DetectHiddenWindows := A_DetectHiddenWindows
    DetectHiddenWindows(true)
    
    _windows  := WinGetList('ahk_class AutoHotkey')
    (_scripts := Map()).capacity := _windows.capacity
    
    for hwnd in _windows {
        title := WinGetTitle(hwnd)
        ; Title looks like "C:\Path\To\Script.ahk - AutoHotkey v2.0"
        ; Remove the " - AutoHotkey" part
        path := RegExReplace(title, " - AutoHotkey v[\.\d]+$")
        if (path)
            _scripts.Set(path, 'running')
    }
  
    DetectHiddenWindows(_DetectHiddenWindows) 
    return _scripts
}