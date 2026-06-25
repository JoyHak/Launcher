Colorize(msg, regex := '', color := 'white', bold := false) {
    ; Applies ANSI codes to the message
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
    
    if (!color || color = 'white')
        return msg
    
    code  := colors.Get(color, 37)  
    
    static esc := Chr(27)
    static end := esc '[0m'
    begin      := esc '[' bold ';' code 'm'
    
    if !regex
        return begin . msg . end

    return RegExReplace(
        msg, 
        regex,
        begin '$1' end
    )
}

DeColorize(str) {
    static esc := Chr(27)

    return RegExReplace(
        str, 
        'U)' esc '\[\d+;\d+m(.+)' esc '\[0m', 
        '$1'
    )
}

({}.DefineProp)(String.prototype, 'Color', {call: Colorize})
({}.DefineProp)(String.prototype, 'Strip', {call: DeColorize})
({}.DefineProp)(String.prototype, 'Print', {call: Print})


Print(msg, color := 'white', bold := false, icon := '') {
    msg .= '`n'
    
    if IsConsole {
        FileAppend(msg.Color(, color, bold), 'CONOUT$')
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

Warning(msg, what := A_ScriptName) => Print(what ' warning - ' msg, 'yellow', , 'Icon!')

Err(msg, what := A_ScriptName) => Print(what ' error - ' msg, 'red', , 'Iconx')

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