;	@(#)reduce_resolution.pro	1.6	
pro reduce_resolution,t,x,t_res, KEPT = kept
;+
; NAME: REDUCE_RESOLUTION
;
; PURPOSE: To reduce obnoxiously large numbers of data points to more
;          manageable ones, for applications which don't need such high
;          time resolution, like summary plots.
;
; INPUTS: T is an array of times, X is an array of time-ordered
;         data. T_RES is the requested time resolution.
;
; KEYWORDS: KEPT is a named array in which the indices of the
;           surviving elements are returned. These indices are with
;           respect to the original T and X, not the reduced
;           ones. This is useful for reducing, say all three
;           components of a magnetometer...call REDUCE_RESOLUTION with
;           the first component, and reduce the other two with the
;           KEPT indices. 
; 
; OUTPUTS: Again, T and X. On output, the time between adjacent points
;          will be between T_RES/2 and T_RES, *except*, of course, in
;          gaps, which may already have been considerably larger than
;          T_RES.
;
; SIDE EFFECTS: T and X will be decimated. 
;
; RESTRICTIONS: None. No input checking is performed either, however. 
;
; MODIFICATION HISTORY: written 13-Jan-97 by Bill Peria UCB/SSL
;
;-

two = 2.d
dtmax = t_res/two

nt = n_elements(t)
dt = t(1l:nt-2l) - t(0l:nt-1l)
kept = lindgen(nt)

neg = where(dt lt 0,nneg)
if nneg gt 0 then begin
    ord = sort(t)
    t = (t(ord))
    x = (x(ord))
    kept = (kept(ord))
endif
   
repeat begin    
    
    check = dt gt dtmax
    too_fine = where(check eq 0,ntoo_fine) 
    ok =       where(check eq 1,nok)
    
    if ntoo_fine gt 1l then begin
        keep = [ok,too_fine(lindgen(ntoo_fine/2l)*2l)]
        keep = (keep(sort(keep)))
        t = (t(keep))
        x = (x(keep))
        kept = (kept(keep))
        
        nt = n_elements(t)
        dt = t(1l:nt-2l) - t(0l:nt-1l)
    endif
    
endrep until (ntoo_fine le 1l)

return
end


