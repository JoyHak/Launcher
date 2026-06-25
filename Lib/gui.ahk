#include "ListViewColors.ahk"

Object.Prototype.DefineProp(
    'Assign', { Call: (ctrl, &var) => (var := ctrl) }
)

Gui.Control.Prototype.DefineProp(
    'Color', { Call: (ctrl, color?) => (
        IsSet(color)
          ? ctrl.Opt(Format('+Redraw +Background{:x}', color))
          : ctrl.Opt(Format('+Redraw -Background')), 
          ctrl
    ) }
)

Gui.Button.Prototype.DefineProp(
    'Default', { Set: (btn, state := true) => (
        btn.Opt(Format('{}Default', state ? '+' : '-'))
    ) }
)

class Settings extends GUI {
    Button(options := '', text := 'Button', &var := '', callback := (*) => 0) {
        return this
          .AddButton('x+m w70 h30 ' options, text)
          .Assign(&var)
          .OnEvent('Click', callback)
    }
    
    List(options := '', columns := [], &var := '', callback := (*) => 0) {
        return this
          .AddListView('xm Grid ' options, columns)
          .Assign(&var)
          .OnEvent('Click', callback)
    }
    
    Label(textOptions := '', editOptions := '', text := 'Label:', &var := '') {
        this.AddText('xm y+10 ' textOptions, text)
        
        return this
          .AddEdit('x+m ' editOptions)
          .Assign(&var)
    }
}

class ScriptManager {
    __New() {
        ; Syntax sugar to improve readability and alignment
        f(name) => this._Fn(name)
        r(base, name) => this._Ref(base, name)
        new := 'xm y+10'
        
        ui := Settings(, 'Script manager')
        ui.SetFont('q5 s11', 'Maple Mono NF CN')
        ui.OnEvent('Close',   WriteAndExit)
        ui.OnEvent('Escape',  WriteAndExit)
        
        ui.AddText(new,        'Defined variables:')
        ui.List('w800 r4',    ['Name', 'Value'],       r(this, 'vars'),     f('LoadVarValue'))
                                                       
        ui.Label(          , 'yp-4 w100', 'Name:',     r(this.vars, 'edit'))
        ui.Label('x+m yp+4', 'yp-4 w550', 'Value:',    r(this.vars, 'content'))
        
        this.vars.btns := {}
        ui.Button(new,         '&Add',                 r(this.vars.btns, 'add'),     f('AddVariable'))
        ui.Button(,            'Remove',               r(this.vars.btns, 'remove'),  f('RemoveVariables'))
        
        ui.AddText('xm y+30',  'Saved scripts:')
        ui.List('w800 r10',   ['Path', 'State'],       r(this, 'scripts'),  f('LoadScriptValue'))
        
        ui.Label(,new ' w700', 'Script or file &path:',r(this.scripts, 'edit'))
        ui.Button(,            '&Browse', ,  f('BrowsePath'))
        
        ui.Label(,'yp-4 w30 Limit1','Separator:',      r(this, 'sep'))
        this.sep.value := Vars['scriptsSep']
        
        ui.Button('yp-2 w40',   'Set', ,    f('SetSeparator'))
        
        this.scripts.btns := {}
        ui.Button(new, 'Add',        r(this.scripts.btns, 'add'),      f('AddScript'))
        ui.Button(,    '&Load',      r(this.scripts.btns, 'load'),    f('LoadScript'))
                                                                 
        ui.Button(,    '&Remove',    r(this.scripts.btns, 'remove'),  f('RemoveScripts'))
        ui.Button(,    '&Disable',   r(this.scripts.btns, 'disable'), f('DisableScripts'))
        ui.Button(,    '&Run',       r(this.scripts.btns, 'run'),     f('RunScripts'))
        ui.Button(,    '&Close',     r(this.scripts.btns, 'close'),   f('CloseScripts'))
                                                                 
        ui.Button(,    '&Refresh',   r(this.scripts.btns, 'refresh'), f('Refresh'))
        ui.Button(,    '&Save', ,    WriteAll)
        ui.Button(,    'Res&tore',,  (*) => (RestoreAll(), this.Refresh()))
        ui.Button('w30',     '&?',,  PrintHelp)
        
        this.status := ui.AddText(new ' w760')
        
        this.colors := Map(
            'disabled', 0xe13936,
            'enabled',  0x81e881,
            'running',  0x34e434,
        )
        
        this.Refresh()
        ui.Show()
        
        ; Don't hook GUI windows creation
        SetTimer(this._Fn('InstallWinHooks'), -2000)
    }

    RefreshVars(*) {
        this.vars.Delete()
        
        for name, value in Vars {
            if (name = 'scriptsSep' || value = 'unset')
                continue
                
            this.vars.Add('', name, value)
        }
        
        this.vars.ModifyCol()  ; Auto-size each column
        this.vars.edit.value := ''
        this.vars.content.value := ''
        this.vars.btns.remove.enabled := false
    }

    RefreshScripts(*) {
        Critical(-1)
        this.scripts.Delete()
                
        imagesId := IL_Create(Scripts.count)
        this.scripts.SetImageList(imagesId)
        
        running := GetRunningScripts()
        states  := Array()  
        count   := 0
        
        for script, state in Scripts {
            if (state = 'unset')
                continue
                
            state := running.Get(script, state)
            
            IL_Add(imagesId, 'Icons\' state '.ico')
            this.scripts.Add('Icon' (++count), script, state)
            states.Push(state)
        }
        
        ; Colors can be applied only after ListView is fullfilled        
        static lvColors := ListViewColors(this.scripts)
        lvColors.Clear()
        
        for state in states {
            lvColors.Cell(A_Index, 2, , this.colors[state])
            lvColors.RowSelected(A_Index, this.colors[state], 0x000000)
        }

        this.scripts.ModifyCol()  ; Auto-size each column
        this.scripts.edit.value := ''
        this.status.text := 'Loaded ' Scripts.Count ' scripts'
        
        ; Reset buttons colors
        for name in this.scripts.btns.OwnProps()
            this.scripts.btns.%name%.Color()
            
        this.scripts.btns.run.enabled    := false
        this.scripts.btns.close.enabled  := false
        this.scripts.btns.remove.enabled := false
        this.scripts.btns.add.default    := true
        this.scripts.btns.add.text       := 'Add'
        
        this.scripts.lastUpdated         := A_TickCount
    }
    
    Refresh(*) {
        this.RefreshVars()
        this.RefreshScripts()
    }

    GetSelected(listView, column := 1) {
        rows := []
        row  := lastRow := 0
        
        loop {
            if !(row := listView.GetNext(lastRow))
                 row := listView.GetNext(lastRow, 'Focused')
            
            if (row = 0)
                break
                
            lastRow := row 
            rows.Push(listView.GetText(row, column))
        }
        
        if !rows.length
            this.status.text := 'Nothing selected'
        
        return rows
    }
    
    GetValue(listView) {
        value := listView.edit.value.Normalize()
        if !value
            this.status.text := 'Value is empty'
        
        return value
    }
    
    LoadVarValue(l, row) {  
        if (row = 0)
            return

        l.edit.value    := l.GetText(row, 1)
        l.content.value := l.GetText(row, 2)  

        l.btns.remove.enabled := true
    }
    
    LoadScriptValue(l, row) {  
        if (row = 0)
            return
         
        path  := l.GetText(row, 1)
        state := l.GetText(row, 2)  
        l.edit.value  := path
        
        if (state = 'disabled') {
            l.btns.add.Color(this.colors['enabled']).text := 'Enable'
            l.btns.add.default := true
            
            l.btns.run.Color().enabled      := false
            l.btns.close.Color().enabled    := false
            l.btns.disable.Color().enabled  := false
        } else {
            l.btns.add.Color().text := 'Add'
            
            l.btns.run.default := true
            l.btns.disable.Color().enabled := true
            l.btns.run.Color(this.colors['running']).enabled := true
            l.btns.close.Color(this.colors['disabled']).enabled := true
        }
        
        l.btns.remove.enabled := true
    }

    RunScripts(*) {
        _scripts := Map()
        for script in this.GetSelected(this.scripts) {            
            if !Scripts.Has(script) {
                Warning('Cannot run non-existing script "' script '"')
                continue
            }
            
            _scripts.Set(script, Scripts[script])
        } else {
            return
        }
        
        RunScripts(_scripts)
        SetTimer(this._Fn('RefreshScripts'), -1000)
    }

    CloseScripts(*) {
        _scripts := Map()
        for script in this.GetSelected(this.scripts) {            
            if !Scripts.Has(script) {
                Warning('Cannot close non-existing script "' script '"')
                continue
            }
            
            _scripts.Set(script, Scripts[script])
        } else {
            return
        }
        
        CloseScripts(_scripts)
        SetTimer(this._Fn('RefreshScripts'), -1000)
    }
        
    RemoveVariables(*) {
        for name in this.GetSelected(this.vars) {            
            if !Vars.Has(name) {
                Warning('Cannot remove non-existing variable "' name '"')
                continue
            }
            
            Vars.Set(name, 'unset')
        } else {
            return
        }

        this.RefreshVars()
    }

    RemoveScripts(*) {
        for script in this.GetSelected(this.scripts) {            
            if !Scripts.Has(script) {
                Warning('Cannot remove non-existing script "' script '"')
                continue
            }
            
            Scripts.Set(script, 'unset')
        } else {
            return
        }

        this.RefreshScripts()
    }
    
    DisableScripts(*) {
        for script in this.GetSelected(this.scripts) {            
            if !Scripts.Has(script) {
                Warning('Cannot disable non-existing script "' script '"')
                continue
            }
            
            Scripts.Set(script, 'disabled')
        } else {
            return
        }

        this.RefreshScripts()
    }
    
    AddVariable(*) {        
        if !(name := this.GetValue(this.vars))
            return
        
        value := this.vars.content.value.Normalize()
        if (value = '' || value = 'unset') {
            if Vars.Has(name)
                Vars[name] := 'unset'
            else
                this.status.text := 'Cannot init variable with empty value'
        } else {
            Vars[name] := ExpandVariables(value)
        }
        
        this.RefreshVars()
    }

    AddScript(*) {
        if !(path := this.GetValue(this.scripts))
            return
        
        path := ExpandVariables(path)

        if (path.Slice(1, 1) = '@') {
            path := path.Slice(2)  ; omit @
            _scripts := ParseFile(path, Vars['scriptsSep'])
        } else {
            _scripts := ParseScripts(path, Vars['scriptsSep'])
        }
            
        for script, state in _scripts
            Scripts.Set(script, state)

        this.RefreshScripts()
    }

    LoadScript(*) {
        if !(path := this.GetValue(this.scripts))
            return

        for script, state in ParseFile(path, Vars['scriptsSep'])
            Scripts.Set(script, state)

        this.RefreshScripts()
    }

    BrowsePath(*) {
        f := FileSelect(1, , 'Select script or text file')
        if !f {
            this.status.text := 'No file is selected'
            return
        }
        
        this.scripts.edit.value := f
        
        this.scripts.btns.add.Color(this.colors['enabled'])
        this.scripts.btns.load.Color(this.colors['enabled'])
    }

    SetSeparator(*) {
        if !this.sep.value {
            this.status.text := 'Separator cannot be empty'
            return
        }
        
        Vars['scriptsSep'] := this.sep.value
    }
    
    
    WinEventProc(hEventHook, hwnd, idObject, idChild, idEventThread, dwmsEventTime) { 
        if (!hwnd)
            return false
        
        static timeoutMs := 2500
        if (A_TickCount - this.scripts.lastUpdated < timeoutMs)
            return false
        
        SetTimer(this._Fn('RefreshScripts'), -timeoutMs)
        return true
    }

    InstallWinHooks() {
        hCallback := CallbackCreate(this._Fn('WinEventProc'), 'Fast', 6)
        
        hHook := DllCall(  
            'SetWinEventHook', 
            'UInt', 0x8002, 
            'UInt', 0x8002, 
            'Ptr',  0, 'Ptr', hCallback, 
            'UInt', 0, 'UInt', 0, 
            'UInt', 0, 
            'Ptr'
        )
        
        OnExit((*) => (DllCall('UnhookWinEvent', 'Ptr', hHook), CallbackFree(hCallback)))
    }
    
    ; Meta-methods to add syntax sugar
    ; and improve code readability
    _Ref(base, name) {
        try {
            desc := base.GetOwnPropDesc(name)
        } catch {
            base.%name% := ''
        }
        
        desc := base.GetOwnPropDesc(name)
        if desc.HasProp('value')
            base.DefineProp(name, make_ref(desc))
            
        return desc.get.ref
        
        make_ref(desc) {
            v := desc.DeleteProp('value')
            desc.get := (this)        => v
            desc.set := (this, value) => v := value
            desc.get.ref := &v  ; Attach the VarRef to the property getter.
            
            return desc
        }
    }
    
    ; Thank you, OwODemonic!
    _Fn(name) => ObjBindMethod(this, name) 
}