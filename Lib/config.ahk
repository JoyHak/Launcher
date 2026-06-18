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
