;+
;FUNCTION:  MGAUSS
;PURPOSE:
;  Evaluates multiple gaussian function with background.
;  This function may be used with the "fit" curve fitting procedure.
;
;KEYWORDS:
;  PARAMETERS: a structure that contain the parameters that define the gaussians
;     If this parameter is not a structure then it will be created.
;
;USAGE:
;  par = mgauss( numg =4 ) ; get parameter structure with 4 gaussian peaks
;  x = findgen(100)/10.
;  y = mgauss(x,param = par)
;  plot,x,y
;RETURNS:
;  result
;
;Written by: Davin Larson
;
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2012-05-29 10:45:13 -0700 (Tue, 29 May 2012) $
; $LastChangedRevision: 10470 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/fitting/mgauss.pro $
;-

function mgauss, x,a, parameters=p,numg=numg,binsize=binsize,shift=shift

if not keyword_set(p) then begin
   if not keyword_set(numg) then numg=1
   g1 = {name:'',a:1.d, x0:0.d, s:1.0d}
   g = replicate(g1,numg)
   g.x0 = findgen(numg)
   p = {func:"mgauss",binsize:keyword_set(binsize) ? binsize : 0.,quantize:1,shift:keyword_set(shift),bkg:0d,xunits:'',a0:0d,a1:1d,g:g}
endif

if n_params() eq 0 then return,p
if n_params() eq 2 then begin                    ;; kludge to make routine work with MPFIT
  xfer_parameters,p,'',a,/array_to_struct
endif

n = n_elements(p.g)
a0 = p.a0
a1 = p.a1
xx = a0 + a1*x
binsize = p.binsize * a1

dx = binsize
if dx eq 0 then begin
    if size(/type, p.bkg) eq 8 then f = func(xx,param=p.bkg) else  f= p.bkg
    for i=0,n-1 do begin
        pg = p.g[i]
        z = (xx - pg.x0)/pg.s
        e = exp(- z^2/2 )
        height = pg.a / pg.s / sqrt(2*!dpi)
        f +=  height * e
    endfor
endif else begin
    if p.quantize ne 0 then begin
        if p.shift then xx = binsize * (floor((xx-a0)/binsize)+.5d) + a0 $
        else xx = binsize * round((xx-a0)/binsize) + a0
    endif
    if size(/type, p.bkg) eq 8 then f = func(xx,param=p.bkg) else  f= p.bkg
    x1= xx - dx/2d
    x2= xx + dx/2d
    s2 = sqrt(2)
    for i=0,n-1 do begin
        pg = p.g[i]
        z1 = (x1-pg.x0)/pg.s/s2
        z2 = (x2-pg.x0)/pg.s/s2
        f += pg.a/2 * (erfc(z1) - erfc(z2)) / dx
    endfor
endelse
;dprint,dlevel=5,[p.bkg,p.g.a,p.g.x0,p.g.s]
return,f
end



;
;function random_mgauss,param=p,seed
;
;numg = n_elements(p.g)
;for i=0,numg-1 do begin
;  r = randomn(seed,p.g[i].a)*p.g[i].s +p.g[i].x0
;  if i eq 0 then rr = r else rr= [rr,r]
;endfor
;return,rr
;end