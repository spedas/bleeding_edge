;+
; NAME:
;        spd_get_sym.pro
;
; PURPOSE:
; 
;        This function provides a convenient way to utilize the
;        USERSYM procedure to create an extended choice of plotting
;        symbols, and is intended to be used directly with the PSYM
;        keyword to PLOT, OPLOT, etc.
;
; CALLING SEQUENCE:
; 
;        Result=spd_get_sym(NUMBER)
;
; INPUTS:
; 
;        NUMBER - symbol number
; 
;               0 : dot
;               1 : filled circle
;               2 : filled upward triangle
;               3 : filled downward triangle
;               4 : filled diamond
;               5 : filled square
;               6 : open circle
;               7 : open upward triangle
;               8 : open downward triangle
;               9 : open diamond
;              10 : open square
;              11 : plus
;              12 : X
;              13 : star
;              14 : filled rightfacing triangle
;              15 : filled leftfacing triangle
;              16 : open rightfacing triangle
;              17 : open leftfacing triangle
;
; OUTPUTS:
; 
;        The function returns the symbol number to be used with the
;        PSYM keyword in the PLOT, OPLOT, etc. commands
;
; SIDE EFFECTS:
; 
;        The USERSYM procedure is used to create a symbol definition.
;
; EXAMPLE:
;
;        To produce a plot using open circles as plotting symbols:
; 
;        PLOT,X,Y,PSYM=spd_get_sym(6)
;
; MODIFICATION HISTORY:
; 
;        Martin Schultz, Harvard University, 22 Aug 1997: VERSION 1.00
;        
;        (with some minor changes to the information in this header by
;        D. Windt, windt@bell-labs.com)
;
;       Forked, renamed for SPEDAS by egrimes on 30 Nov 2018
;-
; Copyright (C) 1997, Martin Schultz, Harvard University
; This software is provided as is without any warranty
; whatsoever. It may be freely used, copied or distributed
; for non-commercial purposes. This copyright notice must be
; kept with any copy of this software. If this software shall
; be used commercially or sold as part of a larger package,
; please contact the author to arrange payment.
; Bugs and comments should be directed to mgs@io.harvard.edu
; with subject "IDL routine sym"
;-------------------------------------------------------------


function spd_get_sym,number

on_error,2                      ; return to caller

if(n_elements(number) eq 0) then return,1 ; default

result=8                        ; default: return psym=8, i.e.
                                ; user defined symbol

; define some help variables for
; circle :
phi=findgen(32)*(!PI*2/32.)
phi = [ phi, phi(0) ]

case number of
    
    0  : result = 3             ; dot
    
    1  : usersym, cos(phi), sin(phi), /fill
                                ; filled circle
    
    2  : usersym, [ -1, 0, 1, -1 ], [ -1, 1, -1, -1 ], /fill
                                ; filled upward triangle
    
    3  : usersym, [ -1, 0, 1, -1 ], [  1, -1, 1, 1 ], /fill
                                ; filled downward triangle
    
    4  : usersym, [ 0, 1, 0, -1, 0 ], [ 1, 0, -1, 0, 1 ], /fill
                                ; filled diamond
    
    5  : usersym, [ -1, 1, 1, -1, -1 ], [ 1, 1, -1, -1, 1 ], /fill
                                ; filled square
    
    6  : usersym, cos(phi), sin(phi)
                                ; open circle
    
    7  : usersym, [ -1, 0, 1, -1 ], [ -1, 1, -1, -1 ]
                                ; open upward triangle
    
    8  : usersym, [ -1, 0, 1, -1 ], [  1, -1, 1, 1 ]
                                ; open downward triangle
    
    9  : usersym, [ 0, 1, 0, -1, 0 ], [ 1, 0, -1, 0, 1 ]
                                ; open diamond
    
    10  : usersym, [ -1, 1, 1, -1, -1 ], [ 1, 1, -1, -1, 1 ]
                                ; open square
    
    11  : result = 1            ; plus
    
    12  : result = 7            ; X
    
    13  : result = 2            ; star
    
    14  : usersym, [ -1, 1, -1, -1 ], [1, 0, -1, 1 ], /fill
                                ; rightfacing triangle, filled
    
    15  : usersym, [ 1, -1, 1, 1 ], [1, 0, -1, 1 ], /fill
                                ; leftfacing triangle, filled
    
    16  : usersym, [ -1, 1, -1, -1 ], [1, 0, -1, 1 ]
                                ; rightfacing triangle, open   
    
    17  : usersym, [ 1, -1, 1, 1 ], [1, 0, -1, 1 ]
                                ; leftfacing triangle, open   
    
    else : begin
        message,/info,'invalid symbol number - set to 1'
        result = 1
    end
    
endcase

return,result
end

