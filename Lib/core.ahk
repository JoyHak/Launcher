GetShortName(path, offset := 2) {
    if (
        pos := InStr(path, '\',, -1, -offset)
     || pos := InStr(path, '/',, -1, -offset)
    ) {
        return '.' SubStr(path, pos)
    }
    
    return path
}

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