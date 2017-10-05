;----------------------
;
;   pro plus_sym
;
;----------------------
;
; creates new symbol, circle or dot, can be scaled
;
;----------------------
;  contains routines/procedures:
;   plus_sym
;----------------------
;example
; to run
;     plus_sym, 0.7,fill=1
;----------------------
; history: 
; this is the ree_sym routine
;----------------------
;
;*******************************************************************
 
 pro mvn_lpw_plus_sym, z, square=square, fill=fill

if not keyword_set(z) then z=1
IF keyword_set(square) then BEGIN
    x=[-z,z,z,-z,-z]
    y=[z, z,-z,-z,z]
    usersym, x, y, fill=fill
ENDIF ELSE BEGIN
    x1 = findgen(21)*!dpi/10
    y1 = z*sin(x1)
    x1 = z*cos(x1)
    usersym, x1, y1, fill=fill
ENDELSE

end
 ;*******************************************************************
 
 