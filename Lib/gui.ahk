#include "ListViewColors.ahk"

Object.Prototype.DefineProp(
    'Assign', { Call: (ctrl, &var) => (var := ctrl) }
)

class Settings extends GUI {
    Button(options := '', text := 'Button', &var := '', callback := (*) => 0) {
        return this
          .AddButton('x+m w70 h30 ' options, text)
          .OnEvent('Click', callback)
    }
    
    List(options := '', columns := [], &var := '', callback := (*) => 0) {
        return this
          .AddListView('xm Grid -Multi ' options, columns)
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
        
        ; todo: add buttons "disable", "clear"
        ui := Settings(, 'Script manager')
        ui.SetFont('q5 s11', 'Maple Mono NF CN')
        ui.OnEvent('Close',  WriteAndExit)
        ui.OnEvent('Escape', WriteAndExit)
        
        ui.AddText(new,        'Defined variables:')
        ui.List('w800 r4',    ['Name', 'Value'],       r(this, 'vars'),     f('LoadValue'))
                                                       
        ui.Label(          , 'yp-4 w100', 'Name:',     r(this.vars, 'edit'))
        ui.Label('x+m yp+4', 'yp-4 w200', 'Value:',    r(this.vars, 'content'))

        ui.Button(new,         'Add', ,     f('AddVariable'))
        ui.Button(,            'Remove', ,  f('RemoveVariable'))
        
        ui.AddText('xm y+30',  'Saved scripts:')
        ui.List('w800 r10',   ['Path', 'State'],       r(this, 'scripts'),  f('LoadValue'))
        
        ui.Label(,  'xm w620', 'Script or file path:', r(this.scripts, 'edit'))
        ui.Button(,            'Browse', ,  f('BrowsePath'))
        
        ui.Label(,'yp-4 Limit1','Separator:',          r(this, 'sep'))
        this.sep.value := Vars['scriptsSep']
        
        ui.Button('yp-2 w40',   'Set', ,    f('SetSeparator'))
        
        this.scripts.buttons := {}
        ui.Button(new, 'Add',     r(this.scripts.buttons, 'add'),     f('AddScript'))
        ui.Button(,    'Load',    r(this.scripts.buttons, 'load'),    f('LoadScript'))
                                                               
        ui.Button(,    'Remove',  r(this.scripts.buttons, 'remove'),  f('RemoveScript'))
        ui.Button(,    'Run',     r(this.scripts.buttons, 'run'),     f('RunScript'))
        ui.Button(,    'Close',   r(this.scripts.buttons, 'close'),   f('CloseScript'))
                                                               
        ui.Button(,    'Refresh', r(this.scripts.buttons, 'refresh'), f('Refresh'))
        ui.Button(,    'Save', ,  WriteAll)
        
        this.status := ui.AddText(new ' w760')
        
        this.Refresh()
        ui.Show()
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
    }

    RefreshScripts(*) {
        this.scripts.Delete()
                
        imagesId := IL_Create(Scripts.count)
        this.scripts.SetImageList(imagesId)
        
        running := GetRunningScripts()
        states  := Array()  
        count   := 0
        
        for script, state in Scripts {
            state := running.Get(script, state)
            
            if (state = 'unset')
                continue
            
            IL_Add(imagesId, 'Icons\' state '.ico')
            this.scripts.Add('Icon' (++count), script, state)
            states.Push(state)
        }
        
        ; Colors can be applied only after ListView is fullfilled
        static colors := Map(
            'disabled', 0xe13936,
            'enabled',  0x81e881,
            'running',  0x34e434,
        )
        
        static lvColors := ListViewColors(this.scripts)
        lvColors.Clear()
        
        for state in states {
            lvColors.Cell(A_Index, 2, , colors[state])
            lvColors.RowSelected(A_Index, colors[state], 0x000000)
        }

        this.scripts.ModifyCol()  ; Auto-size each column
        this.scripts.edit.value := ''
        this.status.text := 'Loaded ' Scripts.Count ' scripts'
    }
    
    Refresh(*) {
        this.RefreshVars()
        this.RefreshScripts()
    }

    GetSelected(listView) {
        row := listView.GetNext()
        if !row
            row := listView.GetNext(, 'Focused')
        
        if !row {
            this.status.text := 'Nothing selected'
            return ''
        }
        
        return listView.GetText(row, 1)
    }
    
    GetValue(listView) {
        value := Trim(listView.edit.value, ' `t`r`n`"`'')
        if !value {
            this.status.text := 'Value is empty'
            return ''
        } 
        
        return value
    }
    
    LoadValue(listView, row) {  
        if (row = 0)
            return
            
        try listView.edit.value  := listView.GetText(row, 1)
        try listView.content.value := listView.GetText(row, 1)
    }

    RunScript(*) {
        if !(script := this.GetSelected(this.scripts))
            return
        
        if !Scripts.Has(script) {
            this.status.text := 'Cannot run non-existing script'
            return
        }
        
        RunScripts(Map(script, Scripts[script]))
        SetTimer(this.RefreshScripts.Bind(this), -2000)
    }

    CloseScript(*) {
        if !(script := this.GetSelected(this.scripts))
            return
        
        if !Scripts.Has(script) {
            this.status.text := 'Cannot close non-existing script'
            return
        }
        
        CloseScripts(Map(script, Scripts[script]))
        SetTimer(this.RefreshScripts.Bind(this), -2000)
    }
        
    RemoveVariable(*) {
        if !(name := this.GetSelected(this.vars))
            return
            
        if !Vars.Has(name) {
            this.status.text := 'Cannot remove non-existing variable'
            return
        }

        Vars.Set(name, 'unset')
        this.RefreshVars()
    }

    RemoveScript(*) {
        if !(script := this.GetSelected(this.scripts))
            return

        if !Scripts.Has(script) {
            this.status.text := 'Cannot remove non-existing script'
            return
        }

        Scripts.Set(script, 'unset')
        this.RefreshScripts()
    }
    
    AddVariable(*) {        
        if !(name := this.GetValue(this.vars))
            return
        
        value := Trim(this.vars.content.value, ' `t`r`n`"`'')
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

        if (SubStr(path, 1, 1) = '@') {
            path := SubStr(path, 2)  ; omit @
            _scripts := ParseFile(path, Vars['scriptsSep'])
        } else {
            _scripts := ParseScripts(path, Vars['scriptsSep'])
        }
            
        for script, state in _scripts {
            Scripts.Set(script, state)
        }

        this.RefreshScripts()
    }

    LoadScript(*) {
        if !(path := this.GetValue(this.scripts))
            return

        for script, state in ParseFile(path, Vars['scriptsSep'])
            Scripts.Set(script, true)

        this.RefreshScripts()
    }

    BrowsePath(*) {
        f := FileSelect(1, , 'Select script or text file')
        if !f {
            this.status.text := 'No file is selected'
            return
        }
        
        this.scripts.edit.value := f
    }

    SetSeparator(*) {
        if !this.sep.value {
            this.status.text := 'Separator cannot be empty'
            return
        }
        
        Vars['scriptsSep'] := this.sep.value
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
    
    _Fn(name) {
        return GetMethod(this, name).Bind(this)
    }
}