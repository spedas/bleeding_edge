;+
;FUNCTION:   plot_positions
;PURPOSE:
;  Procedure that will compute plot positions for multiple plots per page.
;Created by Davin Larson
;
;-



function plot_positions,ysizes=ysizes,options=opts,out_position=pos,ygap=ygap, $
   xsizes=xsizes,xgap=xgap,region=region,aspect = aspect

compile_opt idl2 ;forces array indexing with brackets.  integer constants without type labels default to 32 bit int
                 ;note that array indexing with brackets should be considered mandatory for all future code,
                 ;as IDL 8+ implements parenthetical array indexes very very inefficiently

if not keyword_set(region) then region = !p.region

default = {region:region,position:!p.position,  $
   xmargin:!x.margin,ymargin:!y.margin,charsize:!p.charsize}

if default.charsize eq 0. then default.charsize = 1.

if n_elements(ysizes) eq 0 then ysizes = 1.
if n_elements(xsizes) eq 0 then xsizes = 1.

extract_tags,default,opts

pos = default.position
if keyword_set(region) then pos[[0,2]] = 0.

xspace = default.charsize * !d.x_ch_size/!d.x_size  ; normalized units
yspace = default.charsize * !d.y_ch_size/!d.y_size

if pos[0] eq pos[2] then begin
   reg = default.region
   if reg[0] eq reg[2] then reg=[0.,0.,1.,1.]
   xm = default.xmargin * xspace
   ym = default.ymargin * yspace
   delta = [xm[0],ym[0],-xm[1],-ym[1]]
   pos = reg + delta
endif

nsy = n_elements(ysizes)

;if n_elements(ygap) ne nsy then begin
;   if n_elements(ygap) eq 0 then ygap=1.
;   ygap = replicate(ygap(0),nsy)
;   ygap(0) = 0.
;endif

if n_elements(ygap) eq 0 then ygaps = 1. else ygaps=ygap
if n_elements(ygaps) ne nsy then ygaps= replicate(ygaps[0],nsy)
ygaps[0] = 0

nsx = n_elements(xsizes)

if n_elements(xgap) eq 0 then xgaps = 1. else xgaps=xgap
if n_elements(xgaps) ne nsy then xgaps= replicate(xgaps[0],nsx)
xgaps[0] = 0

;if n_elements(xgap) ne nsx then begin
;   if n_elements(xgap) eq 0 then xgap=1.
;   xgap = replicate(xgap(0),nsx)
;   xgap(0) = 0.
;endif

yw = [pos[1],pos[3]]
xw = [pos[0],pos[2]]

tygap = total(ygaps) * yspace
ynorm = (yw[1]-yw[0]-tygap) / total(ysizes)

txgap = total(xgaps) * xspace
xnorm = (xw[1]-xw[0]-txgap) / total(xsizes)

positions = fltarr(4,nsy*nsx)

ypos = yw[1]
n = 0
for i=0,nsy-1 do begin
  xpos=xw[0]
  gy = ygaps[i] * yspace
  sy = ysizes[i]  * ynorm
  for j=0,nsx-1 do begin
     gx = xgaps[j] * xspace
     sx = xsizes[j]  * xnorm
     p = [xpos+gx,ypos-sy-gy,xpos+gx+sx,ypos-gy]
     positions[*,n] = p
     n = n+1
     xpos = p[2]
  endfor
  ypos = p[1]
endfor

aspect = (positions[3,*]-positions[1,*])/(positions[2,*]-positions[0,*])
aspect = aspect * !d.y_size / !d.x_size
if n_elements(aspect) eq 1 then aspect = aspect[0]




return,positions
end
