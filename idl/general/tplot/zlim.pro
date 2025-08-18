;+
;PROCEDURE:  zlim,lim, [min,max, [log]]
;PURPOSE:
;   To set plotting limits for plotting routines.
;   This procedure will add the tags 'zrange', 'zstyle' and 'xlog' to the
;   structure lim.  This structure can be used in other plotting routines.
;INPUTS:
;   lim:     structure to be added to.  (Created if non-existent)
;   min:     min value of range
;   max:     max value of range
;   log:  (optional)  0: linear,   1: log
;If lim is a string then the limit structure associated with that "TPLOT"
;   variable is modified.
;See also:  "OPTIONS", "YLIM", "XLIM", "SPEC"
;Typical usage:
;   zlim,'ehspec',1e-2,1e6,1   ; Change color limits of the "TPLOT" variable
;                              ; 'ehspec'.
;
;CREATED BY:	Davin Larson
; $LastChangedBy: ali $
; $LastChangedDate: 2020-02-20 12:13:34 -0800 (Thu, 20 Feb 2020) $
; $LastChangedRevision: 28324 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/zlim.pro $
;-
pro zlim,lim,min,max,log,default=default,verbose=verbose
if n_params() eq 1 then begin
   options,lim,'zrange',default=default
   options,lim,'zstyle',default=default
   options,lim,'zlog',default=default
   return
endif
if n_elements(min) eq 2 then max=0
if n_elements(max) eq 0 then range = [0.,0.] else range = float([min,max])
options,lim,'zrange',range[0:1],default=default,verbose=verbose
if range[0] eq range[1] then style=0 else style=1
options,lim,'zstyle',style,default=default,verbose=verbose
if n_elements(log) ne 0 then options,lim,'zlog',log,default=default,verbose=verbose
return
end


