MapWrite(pairsMap, section := 'variables') {
    for var, value in pairsMap {
        switch value, false {
        case 'running':
            ; External state, must be ignored
            continue
        case 'unset':
            ; Internal state, marked for deletion
            IniDelete(INI, section, var)
        default:
            IniWrite(value, INI, section, var)
        }
    }
}

MapRead(pairsMap, section := 'variables') {
    if !FileExist(INI)
        return

    loop parse IniRead(INI, section), '`n' {
        pair := StrSplit(A_LoopField, '=')
        pairsMap.Set(pair[1], pair[2])
    }
}

MapClean(pairsMap, section := 'variables') {
    IniDelete(INI, section)
    pairsMap.Clear()
}

Map.prototype.DefineProp('Clean',    {call: MapClean})
Map.prototype.DefineProp('Write',    {call: MapWrite})
Map.prototype.DefineProp('Read',     {call: MapRead})


WriteAll(*) {
	if FileExist(INI)
    	FileCopy(INI, INI '.bak', true)

    Vars.Write('variables')
    Scripts.Write('scripts')
}

WriteAndExit(*) {
    WriteAll()
    ExitApp()
}

ReadAll(*) {
    Scripts.Read('scripts')
    Vars.Read('variables')
}

RestoreAll(*) {
    if (FileExist(INI) && FileExist(INI '.bak')) {
        ; Swap .bak with current .ini
        FileCopy(INI, INI '.old', true)
        FileCopy(INI '.bak', INI, true)
    }
    
    ReadAll()

	if (FileExist(INI '.bak') && FileExist(INI '.old')) {
		FileDelete(INI '.bak')
    	FileCopy(INI '.old', INI '.bak', true)
	}
}


ExpandVariables(path) {
    ; Performs a dereference of all built-in, declared and env. variables
    ; Returns the path without variables
    pos  := 0
    
    while (pos := path.Match("%(\w+)%", &match, ++pos)) {
        var := match[1]
        if Vars.Has(var) {
            path := path.Replace("%" var "%", Vars[var])
        } else if IsSet(%var%) {
            path := path.Replace("%" var "%", %var%)
        } else if EnvGet(var) {
            path := path.Replace("%" var "%", EnvGet(var))
        } else {
            Err('Unassigned variable: %' var '%.`nPath: "' path '"', 'Variable')
            ExitApp(3)
        }
    }
    
    return path
}