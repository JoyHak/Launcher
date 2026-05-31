GetOutputHandle() {
    static STD_INPUT_HANDLE   := -10
    static STD_OUTPUT_HANDLE  := -11
    static STD_ERROR_HANDLE   := -12

    return DllCall('GetStdHandle', 'int', STD_OUTPUT_HANDLE)     
}

FreeOutput(*) {
    hConsole := DllCall('GetConsoleWindow')
    ControlSend('{Enter}', , 'ahk_id ' hConsole)
    
    DllCall('FreeConsole')
}

AttachOutput() {
    DllCall('FreeConsole')
    DllCall('AttachConsole', 'int', -1)
    
    OnExit(FreeOutput)
    OnError(Exception)
}

Output(text, color := 'white') {
    static colors := Map(
        'black',    0,
        'blue',     1,
        'green',    2,
        'cyan',     3,
        'red',      4,
        'magenta',  5,
        'yellow',   6,
        'white',    7,
        'gray',     8,
    )
    
    normalColor := colors.Get(color, 7)
    
    Print(msg, _color := normalColor) {
        static hConsole := GetOutputHandle()
        DllCall(
            'SetConsoleTextAttribute', 
            'ptr', hConsole, 
            'uint', _color
        )
        
        DllCall(
            'WriteConsoleW',
			'UPtr', hConsole,
			'Str',  msg,
			'UInt', StrLen(msg),
			'UInt*', 0,
			'uint',  0
        )
    }

    pos := 1
    while (pos <= StrLen(text)) {
        if (RegExMatch(text, 's)<(\w+)>(.*?)</\1>', &match, pos)) {
            ; Print normal text before the match
            normalText := SubStr(text, pos, match.pos - pos)
            if (normalText)
                Print(normalText)
            
            ; Handle nested tags
            Output(match[2], match[1])
            
            ; Move position forward
            pos := match.pos + match.len
        } else {
            ; Print remaining text
            Print(SubStr(text, pos))
            break
        }
    }
}

Message(msg, icon := '', normalColor := 'white') {
    try {
        Output(msg '`n', normalColor)
    } catch {    
        msg := RegExReplace(msg, 's)<(\w+)>(.*?)</\1>', '$2')
        MsgBox(msg, A_ScriptName, icon)
    }
}

Verbose(msg) {
    if IsVerbose
        Message(Format('<gray>{}</gray>', msg))
}

Warning(msg, what := A_ScriptName) {
    Message(
        Format('<yellow>{} warning - {}</yellow>', what, msg), 
        'Icon!'
    )
}

Err(msg, what := A_ScriptName) {
    Message(
        Format('<red>{} error - {}</red>', what, msg), 
        'Iconx'
    )
}

Exception(ex, *) {
    Err(ex.message '`n' ex.extra, ex.what)
    ExitApp(12)
}


Colorize(&str, regex, colorTag) {
    str := RegExReplace(
        str, 
        regex,
        Format('<{1}>$0</{1}>', colorTag)
    )
}