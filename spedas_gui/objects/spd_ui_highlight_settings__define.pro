;+ 
;NAME: 
; spd_ui_highlight_settings__define
;
;PURPOSE:  
; highlight properties is an object that holds all parameters associated with
; theh Trace Properties Highlight panel
;
;CALLING SEQUENCE:
; highlightProperties = Obj_New("SPD_UI_HIGHLIGHT_SETTINGS")
;
;INPUT:
; none
;
;KEYWORDS:
; markVertical      flag to mark vertical
; lineStyle         line style object
; symbol            symbol object 
; placement         droplistfor placement of symbol
;                     top, bottom, both top and bottom
; labelWith         0=No label, 1=X value, 2=Y value
; format            numeric format for label 
; markWhenY         flag to mark y value 
; whenYEquals       y value to mark
; markEvery         flag to mark every y value ..
; whenEveryEquals  y value to mark
; setBackground     flag to set background
; backgroundWhenY   droplist of logical operators
; backgroundYValue  value for logical operator
; backgroundColor   r,g,b color for background
;
;OUTPUT:
; highlight property object reference
;
;METHODS:
; SetProperty   procedure to set keywords 
; GetProperty   procedure to get keywords 
; GetAll        returns the entire structure
; GetPlacements returns a string array with placement options
; GetPlacement  return a string with placement option of given index
; GetOperators  returns a string array with operator options ['<','<=', ...]
; GetOperator   return a string with placement option of given index
;
;NOTES:
;  Methods: GetProperty,SetProperty,GetAll,SetAll are now managed automatically using the parent class
;  spd_ui_getset.  You can still call these methods when using objects of type spd_ui_highlight_settings, and
;  call them in the same way as before
;
;$LastChangedBy:pcruce $
;$LastChangedDate:2009-09-10 09:15:19 -0700 (Thu, 10 Sep 2009) $
;$LastChangedRevision:6707 $
;$URL:svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/spedas/spd_ui/objects/spd_ui_highlight_settings__define.pro $
;-----------------------------------------------------------------------------------



FUNCTION SPD_UI_HIGHLIGHT_SETTINGS::Copy
   out = Obj_New('SPD_UI_HIGHLIGHT_SETTINGS')
   selfClass = Obj_Class(self)
   outClass = Obj_Class(out)
   IF selfClass NE outClass THEN BEGIN
       dprint,  'Object classes not identical'
       RETURN, -1
   END
   Struct_Assign, self, out
  ; newLineStyle=Obj_New("SPD_UI_LINE_STYLE")
   IF Obj_Valid(self.lineStyle) THEN newLineStyle=self.lineStyle->Copy() ELSE $
      newLineStyle=Obj_New()
   out->SetProperty, LineStyle=newLineStyle
  ; newSymbol=Obj_New("SPD_UI_SYMBOL")
   IF Obj_Valid(self.symbol) THEN newSymbol=self.symbol->Copy() ELSE $
      newSymbol=Obj_New()
   out->SetProperty, Symbol=newSymbol
   RETURN, out
END ;--------------------------------------------------------------------------------


FUNCTION SPD_UI_HIGHLIGHT_SETTINGS::GetOperators
RETURN, ['<', '<=', '>', '>='] 
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_HIGHLIGHT_SETTINGS::GetOperator, index
   IF N_Elements(index) EQ 0 THEN RETURN, 0
   IF NOT Is_Numeric(index) THEN RETURN, 0
   IF index LT 0 OR index GT 5 THEN RETURN, 0
   operators=self->GetOperators()
RETURN, operators(index)
END ;--------------------------------------------------------------------------------




FUNCTION SPD_UI_HIGHLIGHT_SETTINGS::GetPlacements
RETURN, ['Top', 'Bottom', 'Top and Bottom']
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_HIGHLIGHT_SETTINGS::GetPlacement, index
   IF N_Elements(index) EQ 0 THEN RETURN, 0
   IF NOT Is_Numeric(index) THEN RETURN, 0
   IF index LT 0 OR index GT 5 THEN RETURN, 0
   placements=self->GetPlacements()
RETURN, placements(index)
END ;--------------------------------------------------------------------------------



;PRO SPD_UI_HIGHLIGHT_SETTINGS::Cleanup
;   Obj_Destroy, self.lineStyle
;   Obj_Destroy, self.symbol
;END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_HIGHLIGHT_SETTINGS::Init,     $
              MarkVertical=markvertical,        $ ; flag to mark with vertical
              LineStyle=linestyle,              $ ; line style object
              Symbol=symbol,                    $ ; symbol object
              Placement=placement,              $ ; droplist value of placement location
              LabelWith=labelwith,              $ ; 0=No label, 1=X value, 2=Y value
              Format=format,                    $ ; format for numeric label 
              MarkWhenY=markwheny,              $ ; flag to mark values when y  
              WhenYEquals=whenyequals,          $ ; y value to mark
              MarkEvery=markevery,              $ ; mark every value
              WhenEveryEquals=wheneveryequals,  $ ; y value to mark
              SetBackground=setbackground,      $ ; flag to set background
              BackgroundWhenY=backgroundwheny,  $ ; droplist of when y is (<, >, <=, >=)
              BackgroundYValue=backgroundyvalue,$ ; y value 
              BackgroundColor=backgroundcolor,  $ ; background color
              Debug=debug                         ; set to one for debugging

   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(debug))
      RETURN, 0
   ENDIF
 
   ; Check that all parameters have values
   
   IF N_Elements(placement) EQ 0 THEN placement = 0
   IF N_Elements(labelwith) EQ 0 THEN labelwith = 0
   IF N_Elements(format) EQ 0 THEN format = 0
   IF N_Elements(whenyequals) EQ 0 THEN whenyequals = 0
   IF N_Elements(wheneveryequals) EQ 0 THEN wheneveryequals = 0
   IF N_Elements(backgroundwheny) EQ 0 THEN backgroundwheny = 0
   IF N_Elements(backgroundyvalue) EQ 0 THEN backgroundyvalue = 0
   IF N_Elements(backgroundcolor) EQ 0 THEN backgroundcolor = [0,0,0]
   
   IF NOT Obj_Valid(linestyle) THEN linestyle = Obj_New("SPD_UI_LINE_STYLE")
   IF NOT Obj_Valid(symbol) THEN symbol = Obj_New("SPD_UI_SYMBOL")

  ; Set all parameters
   
   self.markVertical = Keyword_Set(markvertical)
   self.markWhenY = Keyword_Set(markwheny)
   self.markEvery = Keyword_Set(markevery)
   self.setBackground = Keyword_Set(setbackground)
  
   self.placement = placement
   self.labelWith = labelwith
   self.format = format
   self.whenYEquals = whenyequals
   self.whenEveryEquals = wheneveryequals
   self.backgroundwheny = backgroundwheny
   self.backgroundyValue = backgroundyvalue
   self.backgroundColor = backgroundcolor
   self.lineStyle =linestyle
   self.symbol = symbol
                    
RETURN, 1
END ;--------------------------------------------------------------------------------



PRO SPD_UI_HIGHLIGHT_SETTINGS__DEFINE

   struct = { SPD_UI_HIGHLIGHT_SETTINGS, $

              markVertical: 0,             $ ; flag to mark vertical
              lineStyle: Obj_New(),        $ ; line style object
              symbol: Obj_New(),           $ ; symbol object
              placement: 0,                $ ; droplist value of placement location
              labelWith: 0,                $ ; 0=No label, 1=X value, 2=Y value
              format: 0,                   $ ; format for x or y values
              markWhenY: 0,                $ ; flag to mark when y equals value
              whenYEquals: 0,              $ ; y value to mark
              markEvery: 0,                $ ; flag to mark y for every value eq. to
              whenEveryEquals: 0,          $ ; y value for every
              setBackground: 0,            $ ; flag to set background
              backgroundWhenY: 0,          $ ; droplist of logic for when y is
              backgroundYValue: 0,         $ ; numerical value for when y is
              backgroundColor: [0,0,0],     $ ; name for background color
              inherits spd_ui_getset $ ; generalized setProperty/getProperty/getAll/setAll methods   
              
                                    
}

END
