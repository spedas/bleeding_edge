;+
; NAME: INREAL
;
; PURPOSE: To obtain a floating point number from the keyboard.
;
; CALLING SEQUENCE: x = inreal(prompt,default)
; 
; INPUTS: PROMPT - a string that tells the user what to type. You must
;         provide this string, sorry, there's no default.
;
; OPTIONAL INPUTS: DEFAULT - a value to be used if the user just hits
;                  return in response to PROMPT. The default for
;                  DEFAULT is zero.
;
; OUTPUTS: X - if the user manages to type something that can be
;          parsed as a real number, then that number gets returned in
;          X. 
;
; EXAMPLE: gain = inreal('What is the gain?',1.0)
;
; MODIFICATION HISTORY: Written before the dawn of time by Bill Peria,
;                       documented 14-May-1997. 
;
;-
function inreal,query,dxc
if defined(dxc) then dx = dxc else dx = 0.
intype = idl_type(dx)
ok_types = ['float','double','integer','long']
if (where(ok_types eq intype))(0) lt 0 then begin
    message,'Improper type for default value!',/continue
    dx = 0.0
endif

case intype of 
    'integer':begin
        dx = float(dx) 
        double = 0
    end
    'long':begin
        dx = float(dx) 
        double = 0
    end
    'double':begin
        double = 1
    end
    else:begin
        double = 0
    end
endcase

on_ioerror,again
again:dummy = ''
read,query+'['+strcompress(string(dx))+']',dummy
if (dummy ne '') then begin
    if double then begin
        x = double(dummy)
    endif else begin
        x = float(dummy)
    endelse
endif else begin
   x = dx
endelse

return,x
end
