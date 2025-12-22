function resamp,tcall,xcall,tpcall,slow=slow
t = tcall
x = xcall
tp = tpcall
;
;  given a set of points x, sampled at times t, resamp returns a set of 
;      linear interpolates, sampled at tp. 
;
nt = n_elements(t)
fnt = float(nt)
ntp = n_elements(tp)
fntp = float(ntp)
np = [0.0]
dt = max(t) - min(t)
;
; check for linearity, and if it's not there, call FRAC_INDICES...
;
if (((t(nt/2)-(min(t)+dt/2.0)) le dt/1000.) and  $
    (min(t) eq t(0)) and $
    (max(t) eq t(nt-1))) then begin
    np = (fnt-1.0)*(tp - t(0))/(max(t)-t(0))
endif else begin
    np = frac_indices(tp,t)     ; replaced the following commented out
                                ; code with a slicker module from FAST
;    dt = shift(t,-1) - t
;   dt(nt-1) = dt(nt-2)
;   for i=long(0),long(nt-2) do begin
;     in = where((tp gt t(i)) and (tp le t(i+1)),nin)
;     if (nin gt 0) then begin
;        np = [np,float((tp(in) - t(i))/dt(i) + i)]
;     endif
;   endfor
;   ext = where((tp gt t(nt-1)),next)
;   if (next gt 0) then begin
;     np = [np,float((tp(ext)-t(nt-1))/dt(nt-1) + nt - 1)]
;   endif
;   if (ntp ne n_elements(np)) then begin
;      if (ntp eq 1) then begin
;         np = np(1)
;      endif else begin
;         np = np(1:n_elements(np)-1)
;      endelse
;   endif
endelse

xp = interpolate(x,np)
return,xp
end



