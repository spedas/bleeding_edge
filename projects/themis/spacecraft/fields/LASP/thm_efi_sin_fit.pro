;+
; PROCEEDURE: THM_EFI_SIN_FIT, e, t, es=es, ec=ec, per=per 
;
; Called by THM_EFI_REMOVE_OFFSET_AND_SPIN, name, ask=ask 
;
; PURPOSE: DOES A QUICK SIN AND COS FIT
;
; INPUT: 
;    E -         REQUIRED (Electric Field)
;    T -         REQUIRED
;
; WARNING: USE SHORT SEGMENTS
;
;
; OUTPUT: 
;
;    AMP  -         AMPLITUDE
;    PHS  -         PHASE
;    Per  -         PERIOD (Sypply and save a lot of time!)
;
; INITIAL VERSION: REE 08-10-31
; University of Colorado
; MODIFICATION HISTORY: 
;
;-

pro thm_efi_sin_fit, e, t, es=es, ec=ec, per=per 

npts = n_elements(t)

; CHECK IF PER IS SET
IF keyword_set(per) then BEGIN
  es = 2.0*total(e*sin(2.d*!dpi*t/per))/npts
  ec = 2.0*total(e*cos(2.d*!dpi*t/per))/npts
  return
ENDIF

; DO A LOG SEARCH FOR PERIOD
per0 = 2.90d
dper = 0.02d

et   = dblarr(11)
p    = dblarr(11)

per = per0
FOR i = 0, 10 DO BEGIN
  es = 2.0*total(e*sin(2.d*!dpi*t/per))/npts
  ec = 2.0*total(e*cos(2.d*!dpi*t/per))/npts
  et(i) = sqrt(es*es + ec*ec)
  p(i)  = per
  per = per + dper
ENDFOR
;plot, p, et


; SECOND ITERATION
dum = max(et,ind)
per = p((ind-1)>0)
dper = 0.004d
FOR i = 0, 10 DO BEGIN
  es = 2.0*total(e*sin(2.d*!dpi*t/per))/npts
  ec = 2.0*total(e*cos(2.d*!dpi*t/per))/npts
  et(i) = sqrt(es*es + ec*ec)
  p(i)  = per
  per = per + dper
ENDFOR



; THIRD ITERATION
dum = max(et,ind)
per = p((ind-1)>0)
dper = 0.001d
FOR i = 0, 10 DO BEGIN
  es = 2.0*total(e*sin(2.d*!dpi*t/per))/npts
  ec = 2.0*total(e*cos(2.d*!dpi*t/per))/npts
  et(i) = sqrt(es*es + ec*ec)
  p(i)  = per
  per = per + dper
ENDFOR


; FORTH ITERATION
dum = max(et,ind)
per = p((ind-1)>0)
dper = 0.0002d
FOR i = 0, 10 DO BEGIN
  es = 2.0*total(e*sin(2.d*!dpi*t/per))/npts
  ec = 2.0*total(e*cos(2.d*!dpi*t/per))/npts
  et(i) = sqrt(es*es + ec*ec)
  p(i)  = per
  per = per + dper
ENDFOR

; FIFTH ITERATION
dum = max(et,ind)
per = p((ind-1)>0)
dper = 0.00005d
FOR i = 0, 10 DO BEGIN
  es = 2.0*total(e*sin(2.d*!dpi*t/per))/npts
  ec = 2.0*total(e*cos(2.d*!dpi*t/per))/npts
  et(i) = sqrt(es*es + ec*ec)
  p(i)  = per
  per = per + dper
ENDFOR

dum = max(et,ind)
per = p(ind)

; SET SIN AND COS
es = 2.0*total(e*sin(2.d*!dpi*t/per))/npts
ec = 2.0*total(e*cos(2.d*!dpi*t/per))/npts

return
end
