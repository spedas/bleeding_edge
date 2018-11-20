;+
;PROCEDURE:   mvn_swe_fovplot
;PURPOSE:
;  Plots the results of a FOV calibration obtained with mvn_swe_fovcal.
;
;USAGE:
;  mvn_swe_fovplot, dat, result=result
;
;INPUTS:
;       dat:       A FOV calibration structure obtained with mvn_swe_fovcal.
;
;KEYWORDS:
;       BAD:       A set of solid angle bins to ignore when calculating the
;                  azimuth and elevation responses.  Bins blocked by the 
;                  spacecraft are automatically ignored.
;
;       DATE:      Date string associated with calibration ('MMM YYYY').
;
;       CRANGE:    Color scale range.  Default = [0.5,1.5].
;
;       YRANGE:    RGF range for data point plot.  Default = [0,1.4].
;
;       MAP:       Mapping projection.  Can be one of:
;                     'mol' = Mollweide
;                     'cyl' = Cylindrical
;                     'ort' = Orthographic
;                     'ait' = Aitoff (default)
;                     'lam' = Lambert
;                     'gno' = Gnomic
;                     'mer' = Mercator
;
;       LON:       Center longitude for 3D map.  Default = 180.
;
;       LAT:       Center latitude for 3D map.  Default = 0.
;
;       RESULT:    Structure containing the azimuth and elevation responses
;                  with uncertainties.
;
;       CAT:       Print the results.
;
;       PSNAME:    File name for postscript output.
;
;CREATED BY:	David L. Mitchell  2016-08-03
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2018-11-09 11:38:35 -0800 (Fri, 09 Nov 2018) $
; $LastChangedRevision: 26092 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_fovplot.pro $
;-
pro mvn_swe_fovplot, dat, bad=ondx, date=date, crange=crange, yrange=yrange, map=map, $
                     result=result, lon=lon, lat=lat, psname=psname, cat=cat

  @mvn_swe_com

  gud = where(swe_sc_mask[*,1] eq 1, ngud)
  bad = where(swe_sc_mask[*,1] eq 0, nbad)

  mask = replicate(1.,96)
  mask[bad] = !values.f_nan
  if keyword_set(ondx) then begin
    mask[ondx] = !values.f_nan
    doo = 1
  endif else doo = 0

  if (size(date,/type) ne 7) then date = ''
  if (n_elements(crange) ge 2) then crange = minmax(crange) else crange = [0.5, 1.5]
  if (n_elements(yrange) ge 2) then yrange = minmax(yrange) else yrange = [0.0, 1.4]
  if (size(map,/type) ne 7) then map = 'ait'
  if not keyword_set(lon) then lon = 180.
  if not keyword_set(lat) then lat = 0.
  if (size(psname,/type) ne 7) then dops = 0 else dops = 1

; Generate plot data

    k3d = findgen(96)
    ndat = n_elements(dat)
    rms = replicate(0.,96)
    if (ndat eq 1L) then begin
      rgf = dat.rgf
      rms_all = replicate(0.,n_elements(rgf))
    endif else rgf = average(dat.rgf,2,stdev=rms_all,/nan)

    fovcal = swe_3d_struct
    fovcal.project_name = 'SWEA Relative Geometric Factor -'
    fovcal.data_name = date
    fovcal.time = min(dat.time)
    fovcal.end_time = max(dat.time)
    fovcal.units_name = 'EFLUX'

    energy = swe_swp[*,0] # replicate(1.,96)
    fovcal.energy = energy
    fovcal.denergy[0,*] = abs(energy[0,*] - energy[1,*])
    for i=1,62 do fovcal.denergy[i,*] = abs(energy[i-1,*] - energy[i+1,*])/2.
    fovcal.denergy[63,*] = abs(energy[62,*] - energy[63,*])

    de = min(abs(125. - fovcal.energy[*,0]), ebin)
    fovcal.data = replicate(1.,64) # rgf

    elev = transpose(swe_el[*,*,0])
    delev = transpose(swe_del[*,*,0])
    for i=0,95 do begin
      k = i/16
      fovcal.theta[*,i] = elev[*,k]
      fovcal.dtheta[*,i] = delev[*,k]
    endfor

    for i=0,95 do begin
      k = i mod 16
      fovcal.phi[*,i] = swe_az[k]
      fovcal.dphi[*,i] = swe_daz[k]
    endfor

    fovcal.domega = (2.*!dtor)*fovcal.dphi *    $
                    cos(fovcal.theta*!dtor) *   $
                    sin(fovcal.dtheta*!dtor/2.)

    fovcal.magf = [0.,0.,0.]
    fovcal.valid = 1B
    fovcal.gf = 1.
    fovcal.eff = 1.
    fovcal.dtc = 1.

; Make plots

  Twin = !d.window
  dev = !d.name

  if (dops) then begin
    popen, psname
    loadct2,34
  endif else window,5,xsize=825,ysize=1000

; 3D plot

  plot3d_options,map=map
  plot3d_new, fovcal, lat, lon, ebins=[ebin], zrange=crange, noerase=0, stack=[1,2], $
              /noborder
  lab=strcompress(indgen(fovcal.nbins),/rem)
  xyouts,reform(fovcal.phi[63,*]),reform(fovcal.theta[63,*]),lab,align=0.5,$
         charsize=!p.charsize

; XY plot

  !p.multi = [1,1,2,0,0]

  plot,k3d,rgf,xrange=[0,96],/xsty,xticks=6,xminor=4,charsize=1.4, $
       ytitle='Relative Geometric Factor',xtitle='Solid Angle Bin', $
       psym=4,thick=4,yrange=yrange,/ysty,title='',xmargin=[8,5], $
       ymargin=[5,5]
  oploterr,k3d,rgf,rms_all,3

  y = dat.rgf*(mask # replicate(1.,ndat))
  rgf_el = fltarr(6)
  rms_el = fltarr(6)
  for i=0,5 do begin
    rgf_el[i] = average(y[(i*16):(i*16+15),*],stdev=rms,/nan)
    rms_el[i] = rms
  endfor
  for i=0,5 do oplot,[i*16,(i+1)*16],[rgf_el[i],rgf_el[i]],color=4,thick=3
  if (doo) then oplot,k3d[ondx],rgf[ondx],psym=4,thick=4,color=6
  for i=1,14 do oplot,[i*16,i*16],[0,100],line=1

  rgf_az = fltarr(16)
  rms_az = fltarr(16)
  for i=0,15 do begin
    rgf_az[i] = average(y[(16*(indgen(4)+2)+i),*],stdev=rms,/nan)
    rms_az[i] = rms
  endfor

  if (dops) then pclose else wset,Twin

  result = {rgf:rgf, rms:rms_all, rgf_az:rgf_az, rms_az:rms_az, rgf_el:rgf_el, rms_el:rms_el}

; Print results

  if keyword_set(cat) then begin
    rgf2 = rgf
    indx = where(~finite(rgf2), count)
    if (count gt 0) then rgf2[indx] = 1.
    for i=0,90,6 do print,rgf2[i:(i+5)],format='(6(f8.6," , "))'
    print,''
    print,rgf_az,format='(16(f6.2))'
    print,rms_az,format='(16(f6.2))'
    print,''
    print,rgf_el,format='(6(f6.2))'
    print,rms_el,format='(6(f6.2))'
    print,''
  endif

  return
  
end
