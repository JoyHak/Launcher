MapToString(m) {
    str := ''
    for k, v in m {
        str .= '`n' k ' = ' v 
    }
    
    return LTrim(str, '`n')
}

MapWrite(pairsMap, section := 'variables') {
    for var, value in pairsMap {
        if (value = '' || value = 'unset')
            IniDelete(INI, section, var)
        else
            IniWrite(value, INI, section, var)
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
Map.prototype.DefineProp('ToString', {call: MapToString})
Map.prototype.DefineProp('ToGrid',   {call: MapToGrid})
