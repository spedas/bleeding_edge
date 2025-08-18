;1/29/14 DMS -- added normalization constant
;8/17/14 DMS -- Take it out again with correctly normalized v4 DRM.

pro barrel_sp_make_drm, ss, altitude=altitude, angledist=angledist, whichone=whichone

if not keyword_set(angledist) then angledist=1
case angledist of
1: pitch='iso'
2: pitch='mir'
else: message,'invalid value for angular distribution index.'
endcase
if keyword_set(altitude) then ss.altitude=altitude else altitude=ss.altitude
if altitude eq -1. then message,'altitude undefined.'
if not keyword_set(whichone) then whichone=1
if whichone ne 1 and whichone ne 2 then message,'bad response matrix ID number.'

;Set up the response matrix
ctbins = ss.ebins
elebins = ss.elebins
nct = n_elements(ctbins)
nel = n_elements(elebins)
edge_products,ctbins,mean=ctmean,width=ctwidth
edge_products,elebins,mean=elmean,width=elwidth
drm = fltarr(nel-1,nct-1)

;Build the DRM row by row:
for i=0, nel-2 do begin
   row = barrel_sp_drm_row(altitude,elmean[i],ctbins,pitch=pitch)
   drm[i,*] = row
endfor

ss.elebins = elebins

if whichone eq 1 then begin
       ss.drm = drm 
       ss.drmtype = angledist
endif else begin
       ss.drm2 = drm
       ss.drm2type = angledist
endelse

end
