;+
; PROCEEDURE: FF_DCE_FIX, dat, time, zero, zt, ratio, rt
;       
; PURPOSE: Routine called by fa_fields despin to fix zero level and 
;          relative gain of dcE signals. Not for general use.
;
; INPUT: 
;       dat  -        REQUIRED. A DATA ARRAY -  NOT A STRUCTURE!
;       time -        REQUIRED. A DATA ARRAY -  NOT A STRUCTURE!
;       zero -        REQUIRED. The zero level is subtracted.
;       zt   -        REQUIRED. Time array of zero.
;       ratio-        Optional. The ratio is multiplied.
;       rt   -        Time array of ratio.
;
; KEYWORDS: 
;
; CALLING: ff_dce_fix,dat,time,zero,zt,ratio,rt
;
; OUTPUT: Fixes zero level and gain of data.
;
; INITIAL VERSION: REE 97-03-29
; MODIFICATION HISTORY: 
; Space Scienes Lab, UCBerkeley
; 
;-
pro ff_dce_fix, dat, time, zero, zt, ratio, rt

; NO checking! Be careful when you use this program.
npts = n_elements(time)

; Subtract the zero level.
temp = ff_interp(time, zt, zero, delt = 2000.)
dat = dat - temp

; Impose the ratio
IF n_elements(rt) GT 1 then BEGIN
    temp = ff_interp(time, rt, ratio, delt = 2000.)
    dat = dat*temp
ENDIF

return
END



     

