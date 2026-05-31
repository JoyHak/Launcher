ParseScripts(scriptsList, separator := ';', state := 'enabled') {
    _scripts := Map()
    if !(scriptsList && separator)
        return _scripts
    
    ParseArgScripts:
    for script in StrSplit(scriptsList, separator) {
        if !script
            continue
            
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

ParseFile(path, separator := ';', state := 'enabled') {
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
        
        GetScripts(state := 'enabled') {
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
            grid := Vars.ToGrid(['Name', 'Value'])
            Colorize(&grid, 'm)^\s+Name| Value\s*$', 'gray')
            Message(grid)
            
        case '-scripts':
            _scripts := Map()
            running  := GetRunningScripts()
            
            for script, state in Scripts {
                state := running.Get(script, state)
                
                switch state, false {
                case 'disabled':
                    icon  := 'x'
                case 'enabled':
                    icon  := 'o'
                case 'running':
                    icon := '>'
                case 'unset':
                    continue
                }
                
                _scripts.Set(icon ' ' script, state)
            }
            
            grid := _scripts.ToGrid(['  Path', 'State'])
            
            ; Color tags will break grid alignment, 
            ; so they are added after all calculations
            Colorize(&grid, 'm)^x\s+| disabled\s*$', 'red')
            Colorize(&grid, 'm)^o\s+| enabled\s*$',  'cyan')
            Colorize(&grid, 'm)^>\s+| running\s*$',  'green')
            Colorize(&grid, 'm)^\s+Path| State\s*$', 'gray')
            
            Message(grid)
            
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
            
        case '--add', '--enable':
            for script, state in GetScripts() {
                Scripts.Set(script, 'enabled')
                Verbose('Add "' script '"')
            }
            
        case '--disable':
            for script, state in GetScripts() {
                Scripts.Set(script, 'disabled')
                Verbose('Disable"' script '"')
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
            if arg = 'scriptsSep' {
                continue ParseArgs 
            }
                
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