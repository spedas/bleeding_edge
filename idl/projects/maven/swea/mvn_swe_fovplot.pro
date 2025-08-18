;+
;PROCEDURE:   mvn_swe_fovplot
;PURPOSE:
;  Plots the results of a FOV calibration obtained with mvn_swe_fovcal.
;
;USAGE:
;  mvn_swe_fovplot, dat, result=result
;
;INPUTS:
;       dat1:      A FOV calibration structure obtained with mvn_swe_fovcal.
;
;       dat2:      A FOV calibration structure obtained with mvn_swe_fovcal.
;                  If present, create the ratio dat2/dat and propagate errors.
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
; $LastChangedDate: 2023-06-05 12:17:33 -0700 (Mon, 05 Jun 2023) $
; $LastChangedRevision: 31883 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_fovplot.pro $
;-
pro mvn_swe_fovplot, dat1, dat2, bad=ondx, date=date, crange=crange, yrange=yrange, map=map, $
                     result=dat, lon=lon, lat=lat, psname=psname, cat=cat

  @mvn_swe_com
  common colors_com

  ctab = color_table
  crev = color_reverse
  initct, 34  ; shows low values better in specplot

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

  if (size(dat1,/type) eq 8) then begin
    rgf = average(dat1.rgf, 2, stdev=rms, /nan)

    rgf_el = fltarr(6)
    rms_el = rgf_el
    for i=0,5 do begin
      rgf_el[i] = average(rgf[(i*16):(i*16+15),*],/nan)
      rms_el[i] = sqrt(average(rms[(i*16):(i*16+15),*]^2.,/nan))
    endfor

    rgf_az = fltarr(16)
    rms_az = fltarr(16)
    for i=0,15 do begin
      rgf_az[i] = average(rgf[(16*(indgen(4)+2)+i),*],/nan)
      rms_az[i] = sqrt(average(rms[(16*(indgen(4)+2)+i),*]^2.,/nan))
    endfor

    cal1 = {time:dat1.time, rgf:rgf, rms:rms, rgf_az:rgf_az, rms_az:rms_az, $
            rgf_el:rgf_el, rms_el:rms_el}

    dat = cal1
  endif else begin
    print, 'You must provide a calibration structure.'
    return
  endelse

  if (size(dat2,/type) eq 8) then begin
    rgf = average(dat2.rgf, 2, stdev=rms, /nan)

    rgf_el = fltarr(6)
    rms_el = rgf_el
    for i=0,5 do begin
      rgf_el[i] = average(rgf[(i*16):(i*16+15),*],/nan)
      rms_el[i] = sqrt(average(rms[(i*16):(i*16+15),*]^2.,/nan))
    endfor

    rgf_az = fltarr(16)
    rms_az = fltarr(16)
    for i=0,15 do begin
      rgf_az[i] = average(rgf[(16*(indgen(4)+2)+i),*],/nan)
      rms_az[i] = sqrt(average(rms[(16*(indgen(4)+2)+i),*]^2.,/nan))
    endfor

    cal2 = {time:dat1.time, rgf:rgf, rms:rms, rgf_az:rgf_az, rms_az:rms_az, $
            rgf_el:rgf_el, rms_el:rms_el}

    rgf = cal2.rgf/cal1.rgf
    rms = rgf*sqrt((cal2.rms/cal2.rgf)^2. + (cal1.rms/cal1.rgf)^2.)

    rgf_az = cal2.rgf_az/cal1.rgf_az
    rms_az = rgf_az*sqrt((cal2.rms_az/cal2.rgf_az)^2. + (cal1.rms_az/cal1.rgf_az)^2.)

    rgf_el = cal2.rgf_el/cal1.rgf_el
    rms_el = rgf_el*sqrt((cal2.rms_el/cal2.rgf_el)^2. + (cal1.rms_el/cal1.rgf_el)^2.)

    time = [dat1.time, dat2.time]
    time = time[sort(time)]
    rat21 = {time:time, rgf:rgf, rms:rms, rgf_az:rgf_az, rms_az:rms_az, $
             rgf_el:rgf_el, rms_el:rms_el}

    dat = rat21
  endif

; Package plot data into a 3D structure

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
  fovcal.data = replicate(1.,64) # dat.rgf

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
    initct, 34
  endif else begin
    win, /free , xsize=825, ysize=1000, /secondary, dx=10, dy=10
    Cwin = !d.window
  endelse

; 3D plot

  plot3d_options,map=map
  plot3d_new, fovcal, lat, lon, ebins=[ebin], zrange=crange, noerase=0, stack=[1,2], $
              /noborder
  lab=strcompress(indgen(fovcal.nbins),/rem)
  xyouts,reform(fovcal.phi[63,*]),reform(fovcal.theta[63,*]),lab,align=0.5,$
         charsize=!p.charsize

; XY plot

  !p.multi = [1,1,2,0,0]

  k3d = findgen(96)
  plot,k3d,dat.rgf,xrange=[0,96],/xsty,xticks=6,xminor=4,charsize=1.4, $
       ytitle='Relative Geometric Factor',xtitle='Solid Angle Bin', $
       psym=4,thick=4,yrange=yrange,/ysty,title='',xmargin=[8,5], $
       ymargin=[5,5]
  oploterr,k3d,dat.rgf,dat.rms,3
  if (doo) then oplot,k3d[ondx],dat.rgf[ondx],psym=4,thick=4,color=6

  for i=0,5 do oplot,[i*16,(i+1)*16],[dat.rgf_el[i],dat.rgf_el[i]],color=4,thick=3
  for i=1,14 do oplot,[i*16,i*16],[0,100],line=1

  if (dops) then pclose

; Az-EL Plot

  if (dops) then begin
    popen, psname + '_AzEl'
    initct, 34
  endif else begin
    win, /free, xsize=600, ysize=600, relative=Cwin, dx=10, /top
    Awin = !d.window
  endelse

  titlestring = fovcal.project_name + ' ' + fovcal.data_name
  !p.multi = [2,1,2,0,0]
    plot,findgen(16)+0.5,dat.rgf_az,psym=4,xrange=[0,16],/xsty,$
       yrange=[0.5,1.5],/ysty,xtitle='Azlimuth Bin', $
       ytitle='Relative Geometric Factor',charsize=1.4, $
       title = titlestring,thick=3,xticks=4,xminor=4
    oploterr,findgen(16)+0.5,dat.rgf_az,dat.rms_az,3
    oplot,[0,16],[1,1],line=2,color=4

    plot,findgen(6)+0.5,dat.rgf_el,psym=4,xrange=[0,6],/xsty,$
       yrange=[0.5,1.5],/ysty,xtitle='Elevation Bin', $
       ytitle='Relative Geometric Factor',charsize=1.4, thick=3

    oploterr,findgen(6)+0.5,dat.rgf_el,dat.rms_el,3
    oplot,[0,6],[1,1],line=2,color=4
  !p.multi = 0

  if (dops) then pclose

  initct, ctab, reverse=crev
  wset, Twin

; Print results

  if keyword_set(cat) then begin
    rgf2 = dat.rgf
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
