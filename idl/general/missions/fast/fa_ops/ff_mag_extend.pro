;+
; PROCEEDURE: FF_MAG_EXTEND, data, time, n_fit, t_strt=t_strt, t_stop=t_stop
;       
; PURPOSE: Extends data to t_strt and t_stop with ladfit.
;          NOT GENERAL PURPOSE.
;
; INPUT: 
;       data -        REQUIRED. Data to be extended.
;       time -        REQUIRED. Time corrsonding to data.
;       n_fit -       OPTIONAL. Number of points to fit. DEFAULT = 9. 
;
; KEYWORDS: 
;       t_strt -      OPTIONAL. Early time to extend to.
;       t_stop -      OPTIONAL. Late time to extend to.
;
; CALLING: 
;      ff_mag_extend, data, time, n_fit, t_strt=t_strt, t_stop=t_stop
;
; OUTPUT: Adds points to data.
;
; INITIAL VERSION: REE 97-10-20 
; MODIFICATION HISTORY: 
; Space Scienes Lab, UCBerkeley
; 
;-
;       @(#)ff_mag_extend.pro	1.1     

pro ff_mag_extend, data, time, n_fit, t_strt=t_strt, t_stop=t_stop

if not keyword_set(n_fit) then n_fit = 9
npts = n_elements(data)
n_use = n_fit < npts

IF keyword_set(t_strt) then BEGIN
    lfit = ladfit( time(0:n_use-1)-time(0), data(0:n_use-1),/double )
    strt = lfit(0) + (t_strt-time(0)) * lfit(1)
ENDIF

IF keyword_set(t_stop) then BEGIN
    lfit = ladfit(time(npts-n_use:npts-1)-time(0), $
                 data(npts-n_use:npts-1),/double)
    stop = lfit(0) + (t_stop-time(0)) * lfit(1)
ENDIF

if keyword_set(t_strt) AND keyword_set(t_stop) then data = [strt,data,stop]
if (not keyword_set(t_strt) ) AND keyword_set(t_stop) then data = [data,stop]
if keyword_set(t_strt) AND (not keyword_set(t_stop) ) then data = [strt,data]

return
END
