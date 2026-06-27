Colorize(msg, mRegexColor := Map('"', 'green')) {
    ; Searches for text parts by regular expression and applies
    ; specified color (ANSI code).
    ; `mRegexColor` is a `Map` with "regex-color" pairs
    ; or `String` with single color name.
    ; Can create nested colored parts.
    ; https://gist.github.com/JBlond/2fea43a3049b38287e5e9cefc87b2124
    
    static colors := Map(
        'black',    30,
        'red',      31,
        'yellow',   33,
        'gray',     90,
        'crimson',  91,
        'green',    92,
        'orange',   93,
        'blue',     94,
        'purple',   95,
        'cyan',     96,
    )
    
    static esc := Chr(27)
    static end := esc '[0m'
    
    if (mRegexColor is String) {
        if (!mRegexColor || mRegexColor = 'white')
            return msg
        
        code  := colors.Get(mRegexColor, 37)  
        begin := esc '[0;' code 'm'
        
        return begin . msg . end
    }
    
    regex  := ''
    chars  := ''
    chrColors := Map()
    
    index := 1
    idxColors := Array()
    
    for str, color in mRegexColor {
        if (str.length = 1) {
            ; Characters are combined into set []
            chars .= str
            chrColors[str] := colors[color]
        } else {
            ; Patterns are combined using the OR | operator.
            ; Index will be used to indentify pattern color
            regex .= str '(*MARK:' index++ ')|' 
            idxColors.Push(colors[color])
        }
    }
    
    regex .= '(?<chr>[' chars '])(*MARK:chr)'
    
    pos := 1
    len := msg.length
    clrMsg := ''
    
    stack := []
    stack.capacity := mRegexColor.capacity * 2
    
    while (pos <= len) {
        if !msg.Match(regex, &match, pos) {
            ; Remaining text
            clrMsg .= msg.Slice(pos)
            break
        }
        
        ; Normal text before the match
        text := msg.Slice(pos, match.pos - pos)
        if (text)
            clrMsg .= text
        
        if (match.mark != 'chr') {
            ; Atomic pattern that has no pair
            begin  := esc '[0;' idxColors[match.mark] 'm'
            clrMsg .= begin . match[1] . end
            pos    := match.pos + 1
            continue
        }
        
        ; Single characters have a pair: " ", ` `, etc.
        if (stack.Has(-1) && stack[-1] = match.chr) {
            clrMsg .= end
            stack.Pop()
        } else {
            begin  := esc '[0;' chrColors[match.chr] 'm'
            clrMsg .= begin
            stack.Push(match.chr)
        }
        
        ; Move position forward
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
    Err(ex.message '`n' ex.extra, ex.what)
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