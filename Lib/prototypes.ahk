MapToString(m) {
    str := ''
    for k, v in m {
        str .= '`n' k ' = ' v 
    }
    
    return LTrim(str, '`n')
}

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

MapToGrid(m, columns := ['key', 'value']) {
    ; Returns key-value pairs aligned as grid.

    ; Calculate the maximum width of each column 
    ; based on key name and value content
    maxWidths := []
    
    maxWidths.Push(StrLen(columns[1]))
    maxWidths.Push(StrLen(columns[2]))
    
    for key, value in m {            
        if (StrLen(key) > maxWidths[1])
            maxWidths[1] := StrLen(key)
            
        if (StrLen(value) > maxWidths[2])
            maxWidths[2] := StrLen(value)
    }
    
    ; Align Map contents vertically
    fmt(index, str) => Format("{1:-" maxWidths[index] "}", str) . "   "
    line(key, value) => fmt(1, key) . fmt(2, value) . '`n'
    
    grid := '`n' . line(columns[1], columns[2])
    for key, value in m {            
        grid .= line(key, value)
    }
    
    return RTrim(grid, ' `t`n')
}

Map.prototype.DefineProp('Clean',    {call: MapClean})
Map.prototype.DefineProp('Write',    {call: MapWrite})
Map.prototype.DefineProp('Read',     {call: MapRead})
Map.prototype.DefineProp('ToString', {call: MapToString})
Map.prototype.DefineProp('ToGrid',   {call: MapToGrid})

({}.DefineProp)(String.prototype, 'Slice',      {call: SubStr})
({}.DefineProp)(String.prototype, 'Split',      {call: StrSplit})
({}.DefineProp)(String.prototype, 'Replace',    {call: StrReplace})
({}.DefineProp)(String.prototype, 'RTrim',      {call: RTrim})
({}.DefineProp)(String.prototype, 'LTrim',      {call: LTrim})
({}.DefineProp)(String.prototype, 'Trim',       {call: Trim})  
({}.DefineProp)(String.prototype, 'Normalize',  {call: (s) => Trim(s, ' `t`r`n`"`'')})  
({}.DefineProp)(String.prototype, 'Find',       {call: (s, needle, pos := 1) => InStr(s, needle, , pos)})

({}.DefineProp)(String.prototype, 'ShortName',  {call: GetShortName})
({}.DefineProp)(String.prototype, 'Color',      {call: Colorize})

({}.DefineProp)(String.prototype, 'Length',     {get:  StrLen})