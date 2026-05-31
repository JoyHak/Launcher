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

Map.prototype.DefineProp('Clean',    {call: MapClean})
Map.prototype.DefineProp('Write',    {call: MapWrite})
Map.prototype.DefineProp('ToString', {call: MapToString})
