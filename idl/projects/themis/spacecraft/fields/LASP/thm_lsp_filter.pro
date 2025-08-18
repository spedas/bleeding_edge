;+
;FUNCTION:  THM_LSP_FILTER, x, dt, flow, fhigh, db=db
;			
;		       
;PURPOSE:   Filters the data COMP*.
; 
;INPUT:   
;	x         - NEEDED. Just the data. Not a structure or name.
;	dt        - NEEDED. Time between points.
;       freq      - NEEDED. Pole of filter. If band_pass: [f1,f2] f1<f2
;                 - If low-pass: [0,f]. If high-pass [f,0]
; 
; KEYWORDS: 
;       db        - OPTIONAL. If convol option is taken, default = 120. 
;
;
;CREATED BY:	REE, 97-03-17 - modified 97-10-03 REE added buf_dt
;FILE:  fa_fields_filter.pro
;VERSION:  0.0
;LAST MODIFICATION:  
;REE 08-11-02, rewrite for THEMIS - no call external so much slower.
;REE 09-04-30, made it a simple function.
;REE 09-05-05, Added Gaussian option. Changed passband to match digital_fliter
;-

function thm_lsp_filter, x, dt, f_low, f_high, db=db, gaussian=gaussian, wave=wave


; CHECK KEYWORDS
if not keyword_set(db) then db=120.0
flow  = f_low
fhigh = f_high

; CALCULATE FILTER COFS
nyquist = 0.5d/dt
fhigh = double(fhigh/nyquist) < 1.d
flow  = double( flow/nyquist) > 0.d
if fhigh LE 0 then fhigh = 1.d
fmin = min([flow, fhigh])
if fmin eq 0 then fmin = fhigh
npts = long(!pi/fmin) > 1
npts = npts < n_elements(x)

IF keyword_set(gaussian) then BEGIN
  nv = npts*2+1
  v = dindgen(nv)-(nv-1)/2
  cofs = exp(-v*v*fmin*fmin*1.25)
  cofs = cofs/total(cofs)
ENDIF ELSE BEGIN
  cofs = digital_filter(flow,fhigh,db,npts, /double)
  if f(0) eq 0 then cofs = cofs/total(cofs)
ENDELSE

xx =  convol(x,cofs,/edge_t,/nan)

return, xx

END


