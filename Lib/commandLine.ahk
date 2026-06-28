ParseScripts(scriptsList, separator := ';', state := 'enabled') {
    _scripts := Map()
    if !(scriptsList && separator)
        return _scripts
    
    ParseArgScripts:
    for script in scriptsList.Split(separator) {
        if !script
            continue
            
        script := ExpandVariables(script.Normalize())

        if FileExist(script) {
            Verbose('Found "' script '"')
            _scripts.Set(script, state)
            continue ParseArgScripts
        }
        
        SearchScript:
        for path in Scripts {
            if path.ShortName(1).Find(script) {
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
    global IsConsole := AttachConsole()
    
    ParseArgs:
    for args in A_Args {
        pair := args.Split('=')
        arg  := pair[1]
        
        GetValue() {
            if pair.Has(2)
                return pair[2].Normalize()
                
            Err('Missing value for "' arg '"', 'Parameter')
            ExitApp(2)
        }
        
        GetScripts(state := 'enabled') {
            path := ExpandVariables(GetValue())

            if (path[1] = '@') {
                return ParseFile(path.LTrim('@'), Vars['scriptsSep'], state)
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
            Vars
              .ToGrid(['Name', 'Value'])
              .Color([
                'm)', 
                '(^\s+Name| Value\s*$)', 'gray'
              ])
              .Print()
            
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
                    icon  := '>'
                case 'unset':
                    continue
                }
                
                _scripts.Set(icon ' ' script, state)
            }
            
            ; Color codes will break grid alignment, 
            ; so they are added after all ToGrid() calculations
            _scripts
              .ToGrid(['  Path', 'State'])
              .Color([
                'm)',
                '(^x\s+| disabled\s*$)', 'red',
                '(^o\s+| enabled\s*$)',  'cyan',
                '(^>\s+| running\s*$)',  'green',
                '(^\s+Path| State\s*$)', 'gray'
              ])
              .Print()
            
        case '-vars-clear':
            Vars.Clean('variables')
        case '-scripts-clear':
            Scripts.Clean('scripts')
            
        case '-verbose':
            global IsVerbose := true
        
        case '-save': 
            WriteAll()
        case '-restore': 
            RestoreAll()
            
        case '-help', '-h', '-?':
            PrintHelp()    
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