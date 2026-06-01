#include "ListViewColors.ahk"

Gui.Prototype.DefineProp(
    'Button', { Call: (
        (ui, options := '', text := 'Button', callback := (*) => 0) => ui
        .AddButton('x+m w70 h30 ' options, text)
        .OnEvent('Click', callback)
    )}
)

class ScriptManager {
    __New() {
        ; todo: disable, clear
        ui := Gui(, 'Script manager')
        ui.SetFont('q5 s11', 'Maple Mono NF CN')
        ui.OnEvent('Close',  WriteAndExit)
        ui.OnEvent('Escape', WriteAndExit)
        
        ui.AddText('xm',        'Defined variables:')
        this.vars := ui.AddListView('xm w800 Grid -Multi r4',  ['Name', 'Value'])
        this.vars.OnEvent('Click',          this.LoadValue.Bind(this))

        ui.AddText('xm y+10 Section', 'Name:')
        this.vars.edit := ui.AddEdit('x+m ys-4 w100')

        ui.AddText('x+m ys',    'Value:')
        this.vars.content := ui.AddEdit('x+m ys-4 w200')

        ui.Button('xm y+10',    'Add',      this.AddVariable.Bind(this))
        ui.Button(,             'Remove',   this.RemoveVariable.Bind(this))
        
        ui.AddText('xm y+30',   'Saved scripts:')
        this.scripts := ui.AddListView('xm w800 Grid -Multi r10',  ['Path', 'State'])
        this.scripts.OnEvent('Click',       this.LoadValue.Bind(this))
        this.scripts.OnEvent('DoubleClick', this.RunScript.Bind(this))
        
        ui.AddText('xm y+10',   'Script or file path:')
        this.scripts.edit := ui.AddEdit('xm w620')
        
        ui.Button(,             'Browse',   this.BrowsePath.Bind(this))

        ui.AddText('xm y+10',   'Separator:')
        this.sep := ui.AddEdit('x+m yp-4 w30 Limit1', Vars['scriptsSep'])
        ui.Button('yp-2 w40',   'Set',      this.SetSeparator.Bind(this))
        
        ui.Button('xm y+10',    'Add',      this.AddScript.Bind(this))
        ui.Button(,             'Load',     this.LoadScript.Bind(this))

        ui.Button(,             'Remove',   this.RemoveScript.Bind(this))
        ui.Button(,             'Run',      this.RunScript.Bind(this))
        ui.Button(,             'Close',    this.CloseScript.Bind(this))
                                            
        ui.Button(,             'Refresh',  this.Refresh.Bind(this))
        ui.Button(,             'Save',     WriteAll)
        
        this.status := ui.AddText('xm y+10 w760')
        
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
}