;+
; Project     : Solar-B
;
; Name        : widget_valid
;
; Purpose     : check if variable is a valid widget id
;
; Category    : utility widgets
;
; Syntax      : IDL> s=widget_valid(id)
;
; Inputs      : ID = id to check
;
; Outputs     : 1/0 if it is or isn't
;
; Keywords    : None
;
; History     : 12-Jan-2006, Zarro (L-3Com/GSFC) - written
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function widget_valid,id

;-- catch obvious invalid cases (non-existent, non-long, or, negative)

if n_elements(id) Eq 0 then return,0b
if size(id, /type) ne 3 then return, 0b
if id lt 0 then return, 0b
return, widget_info(id, /valid)
end
