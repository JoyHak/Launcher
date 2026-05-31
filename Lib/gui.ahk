ShowAgain(*) {  
    static X, Y
    static pos := MouseGetPos(&X, &Y)
    
    mainMenu.Show(X, Y)
}

CreateMenu(scriptsMap := Scripts) {
    _menu := Menu()
    _menu.Add('Run',   RunScripts.Bind(scriptsMap))
    _menu.Add('Close', CloseScripts.Bind(scriptsMap))
    _menu.Add('Exit',  (*) => ExitApp())
    _menu.Add()
    
    for script, state in scriptsMap {
        name := GetShortName(script)
        
        _menu.Add(name, Select.Bind(script))
        if state 
            _menu.Check(name) 
    }
    
    return _menu
}

Select(script, item, pos, mainMenu) {
    if GetKeyState('LShift') {
        CloseScripts(Map(script, true))
    } else if GetKeyState('LCtrl') {
        RunScripts(Map(script, true))
    } else {
        Scripts[script] ^= 1
        mainMenu.ToggleCheck(item)
    }
    
    ShowAgain()
}