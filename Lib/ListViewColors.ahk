; The class provides methods to set individual colors for ListView rows and/or cells.
; Based on https://github.com/AHK-just-me/AHK2_LV_Colors/blob/main/Sources/Class_LV_Colors.ahk

class ListViewColors {
    __New(listView) {
        ; Set LVS_EX_DOUBLEBUFFER style to avoid drawing issues.
        listView.Opt('+LV0x010000')
        this.listView := listView
        this.hwnd := listView.hwnd
        
        ; Set default colors
        backClr := SendMessage(0x1025, 0, 0, listView)  ; LVM_GETTEXTBKCOLOR
        textClr := SendMessage(0x1023, 0, 0, listView)  ; LVM_GETTEXTCOLOR
        this.backClr := backClr
        this.textClr := textClr
        this.Showcolors()
        
        ; Set capacity
        this.rowsCount := listView.GetCount()
        this.colsCount := listView.GetCount('col')
        
        this.rows := Map()
        this.rows.capacity := this.rowsCount
        this.selRows := Map()
        this.selRows.capacity := this.rowsCount
        
        this.cells := Map()
        this.cells.capacity := this.rowsCount
    }
   
    __Delete() {
        this.Hidecolors()
        if WinExist(this.hwnd)
           WinRedraw(this.hwnd)
    }
   
    Clear() {
        this.rows.Clear()
        this.rows.capacity  := this.rowsCount
        this.cells.Clear()
        this.cells.capacity := this.rowsCount
        return true
    }
    
    Row(row, backClr?, textClr?, rowsMap := this.rows) {
        if !this.hwnd
           return false
        if !(IsSet(backClr)|| IsSet(textClr))
           return false     
           
        if (row > this.rowsCount)
           return false

        if rowsMap.Has(row)
            rowsMap.Delete(row)
        
        rowsMap[row] := Map(
            'back', IsSet(backClr) ? this.BGR(backClr) : this.backClr, 
            'text', IsSet(textClr) ? this.BGR(textClr) : this.textClr
        )
        
        return true
    }
    
    RowSelected(row, backClr?, textClr?) => this.Row(row, backClr, textClr, this.selRows)
   
    Cell(row, col, backClr?, textClr?) {
        if !(this.hwnd)
           return false
        if !(IsSet(backClr)|| IsSet(textClr))
           return false   
           
        if ((row > this.rowsCount) || (col > this.colsCount))
           return false
                   
        if (this.cells.Has(row) && this.cells[row].Has(col))
           this.cells[row].Delete(col)
        
        if !this.cells.Has(row) {
           this.cells[row] := []
           this.cells[row].capacity := this.colsCount
        }
           
        if (col > this.cells[row].length)
           this.cells[row].length := col
           
        this.cells[row][col] := Map(
            'back', IsSet(backClr) ? this.BGR(backClr) : this.backClr, 
            'text', IsSet(textClr) ? this.BGR(textClr) : this.textClr
        )
        
        return true
    }
   
    Showcolors() {
        if this.HasOwnProp('onNotifyFunc')
            return false
   
        this.onNotifyFunc := ObjBindMethod(this, 'NM_CUSTOMDRAW')
        this.listView.OnNotify(-12, this.onNotifyFunc)
        WinRedraw(this.hwnd)
      
        return true
    }
   
    Hidecolors() {
        if !this.HasOwnProp('onNotifyFunc')
            return false
            
        this.listView.OnNotify(-12, this.onNotifyFunc, 0)
        this.DeleteProp('onNotifyFunc')
        WinRedraw(this.hwnd)
        
        return true
    }
   
    NM_CUSTOMDRAW(listView, lParam) {
        ; structs offsets
        Static SIZE_NMHDR        := A_PtrSize * 3                      ; Size of NMHDR structure
        Static SIZE_NCD          := SIZE_NMHDR + 16 + (A_PtrSize * 5)  ; Size of NMCUSTOMDRAW structure
        Static OFFSET_ITEM       := SIZE_NMHDR + 16 + (A_PtrSize * 2)  ; Offset of dwItemSpec (NMCUSTOMDRAW)
        Static OFFSET_ITEM_STATE := OFFSET_ITEM + A_PtrSize            ; Offset of uItemState (NMCUSTOMDRAW)
                                                                       
        Static OFFSET_TEXT_CLR   := SIZE_NCD                           ; Offset of clrText    (NMLVCUSTOMDRAW)
        Static OFFSET_BACK_CLR   := OFFSET_TEXT_CLR + 4                ; Offset of clrTextBk  (NMLVCUSTOMDRAW)
        Static OFFSET_SUBITEM        := OFFSET_BACK_CLR + 4                ; Offset of iSubItem   (NMLVCUSTOMDRAW)
        
        ; current draw stage
        static CDDS_SUBITEMPREPAINT   := 0x030001
        static CDDS_ITEMPREPAINT      := 0x010001
        static CDDS_PREPAINT          := 0x000001
        
        ; returns
        static CDRF_NOTIFYITEMDRAW    := 0x20
        static CDRF_NOTIFYSUBITEMDRAW := 0x020
        static CDRF_NEWFONT           := 0x02
        
        if (!this.hwnd || (NumGet(lParam, 'UPtr') != this.hwnd))
           return
        
        Critical(-1)
        DrawStage := NumGet(lParam + SIZE_NMHDR, 'UInt')
        
        ; rows and columns are 1-based
        row  := NumGet(lParam + OFFSET_ITEM,   'UPtr') + 1
        col  := NumGet(lParam + OFFSET_SUBITEM, 'Int') + 1
        item := row - 1   ; item is 0-based
        
        
        switch DrawStage {
        case CDDS_SUBITEMPREPAINT:
            if (this.cells.Has(row) && this.cells[row].Has(col)) {
                colBackClr := this.cells[row][col]['back']
                colTextClr := this.cells[row][col]['text']
            } else {
                colBackClr := this.rowBackClr
                colTextClr := this.rowTextClr
            }
            
            ; Set the colors
            NumPut('UInt', colBackClr, lParam + OFFSET_BACK_CLR)
            NumPut('UInt', colTextClr, lParam + OFFSET_TEXT_CLR)
            
            if (col <= this.cells[row].Length)
                return CDRF_NOTIFYSUBITEMDRAW
                
            return 0
        
        case CDDS_ITEMPREPAINT:
            static LVM_GETITEMSTATE := 0x102C
            static LVIS_SELECTED    := 0x0002
            if (this.selRows.Has(row)
             && SendMessage(LVM_GETITEMSTATE, item, LVIS_SELECTED, this.hwnd)) {
                ; Remove the CDIS_SELECTED and CDIS_FOCUS from uItemState
                static CDIS_SELECTED := 0x0001
                static CDIS_FOCUS    := 0x0010
                flag  := CDIS_SELECTED | CDIS_FOCUS
                
                state := NumGet(lParam + OFFSET_ITEM_STATE, 'UInt')
                NumPut('UInt', state & ~flag, lParam + OFFSET_ITEM_STATE)
                
                ; Set the colors
                NumPut('UInt', this.selRows[row]['back'], lParam + OFFSET_BACK_CLR)
                NumPut('UInt', this.selRows[row]['text'], lParam + OFFSET_TEXT_CLR)
                  
                return CDRF_NEWFONT
            }
            
            if this.rows.Has(row) {
                this.rowBackClr := this.rows[row]['back']
                this.rowTextClr := this.rows[row]['text']
            } else {
                this.rowBackClr := this.backClr
                this.rowTextClr := this.textClr
            }
           
            if (this.cells.Has(row))
                return CDRF_NOTIFYITEMDRAW
               
            NumPut('UInt', this.rowTextClr, lParam + OFFSET_TEXT_CLR)
            NumPut('UInt', this.rowBackClr, lParam + OFFSET_BACK_CLR)
            return 0
        
        case CDDS_PREPAINT:
            return CDRF_NOTIFYITEMDRAW
            
        default:
            return 0
        }
    }
   
    BGR(color) {
        if (color = 0)
            return 0
            
        return ((color >> 16) & 0xFF) | (color & 0x00FF00) | ((color & 0xFF) << 16)
    }
}