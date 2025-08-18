;+ 
;NAME: 
; spd_ui_symbol__define
;
;PURPOSE:  
; generic object for IDL symbols
;
;CALLING SEQUENCE:
; symbol = Obj_New("SPD_UI_SYMBOL")
;
;INPUT:
; none
;
;KEYWORDS:
; name       name of symbol
;              0 = No symbol
;              1 = Plus sign, `+' (default)
;              2 = Asterisk
;              3 = Period (Dot)
;              4 = Diamond
;              5 = Triangle
;              6 = Square
;              7 = X
;              8 = "Greater-than" Arrow Head (>)
;              9 = "Less-than" Arrow Head (<)
; id         IDL graphics symbol index (0-9)
; show       set this to display symbol (default = 1)
; color      name of the color for this symbol (default is black)
; rgb        [r, g, b] value for the color for this symbol 
; fill       set this to fill symbol (default = 0)
; size       size of the symbol (default = 2)
;
;OUTPUT:
; symbol object reference
;
;METHODS:
; GetProperty
; GetAll
; SetProperty
; GetSymbolName
; GetSymbolId
; GetSymbols
;
;
;NOTES:
;  Methods: GetProperty,SetProperty,GetAll,SetAll are now managed automatically using the parent class
;  spd_ui_getset.  You can still call these methods when using objects of type spd_ui_symbol, and
;  call them in the same way as before
;  
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_symbol__define.pro $
;-----------------------------------------------------------------------------------



FUNCTION SPD_UI_SYMBOL::Copy
   out = Obj_New("SPD_UI_SYMBOL")
   selfClass = Obj_Class(self)
   outClass = Obj_Class(out)
   IF selfClass NE outClass THEN BEGIN
       dprint,  'Object classes not identical'
       RETURN, 1
   END
   Struct_Assign, self, out
   RETURN, out
END ;--------------------------------------------------------------------------------


FUNCTION SPD_UI_SYMBOL::GetSymbolName, SymbolId=symbolid

   IF N_Elements(symbolid) EQ 0 THEN RETURN, self.name
   IF NOT Is_Numeric(symbolid) THEN RETURN, -1
   IF symbolid LT 0 OR symbolid GT 8 THEN RETURN, -1   
   symbolList = self->GetSymbols()
   RETURN, symbolList[symbolid]
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_SYMBOL::GetSymbolId, SymbolName=symbolname
   IF N_Elements(symbolname) EQ 0 THEN RETURN, self.id
   IF Is_Numeric(symbolname) THEN RETURN, -1
   symbolList = self->GetSymbols()   
   symbolId=where(symbolList EQ symbolname)   
   RETURN, symbolId
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_SYMBOL::GetSymbols
symbolList = ['Plus Sign', 'Asterisk', 'Period (Dot)', $
'Diamond', 'Triangle', 'Square', 'X', 'Greater-than', 'Less-than']
RETURN, symbolList
END ;--------------------------------------------------------------------------------


;PRO SPD_UI_SYMBOL::Cleanup 
;   
;END ;--------------------------------------------------------------------------------


  
FUNCTION SPD_UI_SYMBOL::Init,    $ ; The INIT method of the symbol object
            Name=name,           $ ; name of symbol (plus, asterisk, ...)
            ID=id,               $ ; IDL graphics symbol index (1-9)
            Show=show,           $ ; flag to display symbol 
            Color=color,         $ ; name of color
            Fill=fill,           $ ; flag to fill symbol
            Size=size,           $ ; size of symbol
            Debug=debug            ; flag to debug

   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(debug))
      RETURN, 0
   ENDIF
  
   ; Check that all parameters have values
   
   IF N_Elements(name) EQ 0 THEN name = 'Plus Sign'
   IF N_Elements(id) EQ 0 THEN id = 1   
   IF id LT 1 OR id GT 10 THEN RETURN, 0 
   IF N_Elements(show) EQ 0 THEN show = 0
   IF N_Elements(color)EQ 0 THEN color = [0,0,0]
   IF N_Elements(fill) EQ 0 THEN fill = 0
   IF N_Elements(size) EQ 0 THEN size = 2

  ; Set all parameters

   self.name = name
   self.id = id
   self.show = show
   self.color = color
   self.fill = fill
   self.size = size
  
   RETURN, 1
END ;--------------------------------------------------------------------------------                 

PRO SPD_UI_SYMBOL__DEFINE

   struct = { SPD_UI_SYMBOL,          $

              name      : ' ',        $ ; the name of the symbol 
              id        : 0,          $ ; IDL graphics symbol index (1-9)
              show      : 0,          $ ; flag to display symbol
              color     : [0,0,0],    $ ; rbg values for color
              fill      : 0,          $ ; flag to fill symbol 
              size      : 0,          $ ; symbol size 
              INHERITS SPD_UI_READWRITE, $ ; generalized read/write methods
              inherits spd_ui_getset $ ; generalized setProperty/getProperty/getAll/setAll methods 
                                     
}

END
