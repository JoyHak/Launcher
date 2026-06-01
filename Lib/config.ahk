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
    Vars.Write('variables')
    Scripts.Write('scripts')
}

WriteAndExit(*) {
    WriteAll()
    ExitApp()
}