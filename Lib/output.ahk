Colorize(msg, aRegexColor := Map('"', 'green')) {
    ; Searches for text parts by regular expression and applies
    ; specified color (ANSI code).
    ; `aRegexColor` is an `Array` with "regex, color" pairs
    ; or `String` with single color name.
    ; Can create nested colored parts.
    ; https://gist.github.com/JBlond/2fea43a3049b38287e5e9cefc87b2124
    
    static colors := Map(
        'black',    30,
        'red',      31,
        'orange',   33,
        'magenta',  35,
        'gray',     90,
        'crimson',  91,
        'green',    92,
        'yellow',   93,
        'blue',     94,
        'purple',   95,
        'cyan',     96,
    )
    
    static esc := Chr(27)
    static end := esc '[0m'
    
    if (aRegexColor is String) {
        if (!aRegexColor || aRegexColor = 'white')
            return msg
        
        code  := colors.Get(aRegexColor, 37)  
        begin := esc '[0;' code 'm'
        
        return begin . msg . end
    }
    
    regex := ''
    if (aRegexColor[1] ~= 'm)^\w+\)$') {
        ; Options comes first
        regex := aRegexColor.RemoveAt(1)
    }
    
    ; Convert input color names to ANSI codes
    chars     := ''
    chrColors := Map()
    chrColors.capacity := aRegexColor.capacity
    
    index     := 1
    idxColor  := 1
    
    loop (aRegexColor.length / 2) {
        str   := aRegexColor[index++]
        color := aRegexColor[index++]

        if (str.length = 1) {
            ; Characters are combined into set []
            chars .= str
            chrColors[str] := colors[color]
        } else if (str[1] = '/') {
            ; Characters escaped with slash are combined into groups
            str := str.Slice(2)
            chrColors[str] := colors[color]
            regex .= '(' str ')(*MARK:chr)|' 
        } else {
            ; Patterns are combined using the OR | operator.
            ; Index will be used to indentify pattern color
            regex .= str '(*MARK:' idxColor ')|' 
            chrColors[String(idxColor++)] := colors[color]
        }
    }
    
    if chars
        regex .= '([' chars '])(*MARK:chr)'
    else
        regex := regex.RTrim('|')
        
    ; Branch reset allows to extract 1st capturing group 
    ; from any found pattern, separated by the OR operator. 
    ; I.e. it gives polymorphism. Regardless of capturing groups 
    ; count match[1] always returns captured text.
    regex := '(?|' regex ')'
        
    ; Parse the message
    pos := 1
    len := msg.length
    clrMsg := ''
    
    stack := []
    stack.capacity := aRegexColor.capacity * 2
    
    while (pos <= len) {
        if !msg.Match(regex, &match, pos) {
            ; Remaining text
            clrMsg .= msg.Slice(pos)
            break
        }
        
        ; Normal text before the match
        clrMsg .= msg.Slice(pos, match.pos - pos)
        
        if (match.mark != 'chr') {
            ; Atomic pattern that has no pair
            begin  := esc '[0;' chrColors[match.mark] 'm'
            if (stack.Has(-1)) {
                _end := esc '[0;' chrColors[stack[-1]] 'm'
                clrMsg .= begin . match[1] . _end
            } else {
                clrMsg .= begin . match[1] . end
            }
            pos    := match.pos + match.len
            continue
        }

        ; Characters that have a pair: " ", ` `, etc. (non-atomic)
        ; Can consist of multiple characters if they were 
        ; escaped with a slash: /** /**, /" /"
        if (stack.Has(-1) && stack[-1] = match[1]) {
            clrMsg .= end
            stack.Pop()
        } else {
            begin  := esc '[0;' chrColors[match[1]] 'm'
            clrMsg .= begin
            stack.Push(match[1])
        }
        
        pos := match.pos + 1
    }
    
    return clrMsg
}

DeColorize(str) {
    ; Strips (removes) all ANSI codes
    static esc := Chr(27)
    return RegExReplace(str, 'U)' esc '\[\d+(;\d+)?m')
}

({}.DefineProp)(String.prototype, 'Color',  {call: Colorize})
({}.DefineProp)(String.prototype, 'Strip',  {call: DeColorize})
({}.DefineProp)(String.prototype, 'Print',  {call: Print})


Print(msg, color := 'white', icon := '') {
    msg .= '`n'
    
    if IsConsole {
        FileAppend(msg.Color(color), 'CONOUT$')
    } else {
        MsgBox(msg.Strip(), A_ScriptName, icon)
    }
    
    return true
}

Verbose(msg) {
    if IsVerbose
        return Print(msg, 'gray')
        
    return false
}

Warning(msg, what := A_ScriptName) => Print(what ' warning - ' msg, 'yellow', 'Icon!')

Err(msg, what := A_ScriptName) => Print(what ' error - ' msg, 'red', 'Iconx')

Exception(ex, *) {
    Err(ex.message '`n' ex.extra, ex.what ' uncaught')
    ExitApp(12)
}


FreeOutput(*) {
    if (hConsole := DllCall('GetConsoleWindow'))
        ControlSend('{Enter}', , 'ahk_id ' hConsole)
        
    return DllCall('FreeConsole')
}

AttachConsole() {
    if !DllCall("AttachConsole", "int", -1)
        return false
    
    static STD_INPUT_HANDLE   := -10
    static STD_OUTPUT_HANDLE  := -11
    static STD_ERROR_HANDLE   := -12
    
    if !(hConsole := DllCall("GetStdHandle", "int", STD_OUTPUT_HANDLE))
        return false
    
    ; Enable ANSI codes processing
    if DllCall("GetConsoleMode", "Ptr", hConsole, "UIntP", &mode := 0) {
        mode |= 0x0004  ; ENABLE_VIRTUAL_TERMINAL_PROCESSING
        DllCall("SetConsoleMode", "Ptr", hConsole, "UInt", mode)
    }

    OnExit(FreeOutput)
    OnError(Exception)
    
    return hConsole
}