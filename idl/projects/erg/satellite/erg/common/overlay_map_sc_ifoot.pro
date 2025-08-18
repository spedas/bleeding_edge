; A generic program to draw footprint positions of spacecraft on the 
; polar plot. 

PRO overlay_map_sc_ifoot, vn_glat, vn_glon, trange, $
  plottime=plottime, $
  force_chscale=force_chscale, changle=changle,$
  force_charthick=force_charthick, $
  geo_plot=geo_plot, $
  spellout=spellout, $
  notimelabel=notimelabel, $
  notick=notick, $
  trace_color=trace_color, $
  force_symsize=force_symsize, $
  force_linethick=force_linethick, $
  force_symthick=force_symthick, $
  draw_plottime_fp=draw_plottime_fp, fp_time=fp_time, $
  fp_psym=fp_psym, fp_symsize=fp_symsize, fp_symthick=fp_symthick, $
  fp_color=fp_color, $
  mintick=mintick, $
  help=help

;Usage
  IF KEYWORD_SET(help) THEN BEGIN
    PRINT,"Usage:"
    PRINT," overlay_map_sc_ifoot, 'thm_state_pos_ifoot_geo_lat', 'thm_state_pos_ifoot_geo_lon',['2011-03-01/04:00','2011-03-01/12:00'], /geo_plot"
    RETURN
  ENDIF


; Check the arguments 
  
  npar = n_params()
  if npar ne 2 and npar ne 3  then return
  if npar eq 2 then begin
    get_timespan, tr 
    trange = tr 
  endif
  
  if strlen( tnames(vn_glat) ) eq 0 then return
  if strlen( tnames(vn_glon) ) eq 0 then return
  vn_glat = tnames(vn_glat) & vn_glon = tnames(vn_glon)
  trange = time_double(trange)
  if keyword_set(plottime) then tp=time_double(plottime) $
  ELSE tp=0
  
  scname = (strsplit(vn_glat, '_',/ext))[0] 
  
; Set the paramters

  ts = trange[0]
  te = trange[1]

; Set the plot interval  
  get_timespan, tr_orig
  timespan, [ts,te]
  
; Clip the data for the plot interval
  get_data, vn_glat, data=ttglat
  get_data, vn_glon, data=ttglon
  tsidx = nn( ttglat.x, ts ) & teidx = nn( ttglat.x, te )
  tglat = { x:ttglat.x[tsidx:teidx], y:ttglat.y[tsidx:teidx] }
  tglon = { x:ttglon.x[tsidx:teidx], y:ttglon.y[tsidx:teidx] }
  
  if keyword_set(geo_plot) or !map2d.coord eq 0 then begin
    tlat = tglat
    tlon = tglon
    tmlt = {x: tglon.x, y:tglon.y/360.*24.}
      ;a dummy variable to get through the following process
  endif else begin
    tstr = time_struct(ts) 
    aacgmloadcoef, tstr.year
    h = replicate( 100., n_elements(tglat.x) )
    aacgmconvcoord,tglat.y,tglon.y, h, mlat, mlon, err, /TO_AACGM
    tlat = {x:tglat.x, y:mlat}
    if tp le 0 then begin
      tstr = time_struct( tglat.x )
      yr = tstr.year & yrsec = long( (tstr.doy-1)*86400L + tstr.sod )
    endif else begin
      tstr = time_struct(tp)
      yr = replicate( tstr.year, n_elements(tglat.x) )
      yrsec = replicate( long( (tstr.doy-1)*86400L+tstr.sod ), n_elements(tglat.x) )
    endelse
    t = aacgmmlt(yr,yrsec, (mlon+360.) mod 360. )
    tmlt = { x:tglat.x, y:t }
  endelse
  
  
  idx=WHERE( tlat.x GE ts AND tlat.x LE te, cnt)
  IF cnt LT 1 THEN BEGIN
    PRINT, 'No data in the time range'
    PRINT, time_string([ts,te]) 
    RETURN
  ENDIF
  tdbl_clip = tlat.x[idx] 
  lat_clip = tlat.y[idx] & mlt_clip = tmlt.y[idx]
  
; Convert (lat,mlt) to the plot coordinates
  phi_clip= mlt_clip/24.*360.  ;[deg]
  
  x = phi_clip & y = lat_clip

;;;; Plot start
  
  
  
  ;Trajectory
  if keyword_set(force_linethick) then thick=force_linethick else thick=1
  if ~keyword_set(trace_color) then trace_color = !p.color ; foreground color
  OPLOT,x,y, linestyle=0, thick=thick, color=trace_color 

  
  
  ;hourly ticks on trajectory
        tdbl = ts + 3600* DINDGEN(ROUND(te-ts)/3600+1)
        if keyword_set(mintick) then tdbl = ts + 60* DINDGEN(ROUND(te-ts)/60+1)
        lat = INTERPOL( tlat.y, tlat.x, tdbl, /spline)
        mlt = INTERPOL( tmlt.y, tmlt.x, tdbl, /spline)
        phi= mlt/24.*360.

        x = phi & y = lat

        IF !D.WINDOW EQ 1 THEN chscale=1.0 ELSE chscale=1.0
        IF KEYWORD_SET(force_chscale) THEN chscale = force_chscale
        if keyword_set(force_charthick) then charthick = force_charthick else charthick = 1.
        if keyword_set(force_symsize) then symsz = force_symsize else symsz = 1.0
        if keyword_set(force_symthick) then symthk = force_symthick else symthk = 1.0
        if ~keyword_set(notick) then $
          OPLOT,x,y, linestyle=0, psym=1, color=trace_color, thick=symthk, symsize=symsz
        
        ;Draw the labels by the trajectory
        if ~keyword_set(notimelabel) then begin
          if ~keyword_set(changle) then changle=0.
          dr =1. & chunit = 10. ;apart by dr*chunit*chsz
          chsz = !p.charsize*chscale
          xch0 = x[0] & ych0 = y[0]
          devc = convert_coord(xch0,ych0,/data,/to_device)
          xyzch = convert_coord(devc[0]+dr*chsz*chunit*cos(changle*!dtor),$
            devc[1]+dr*chsz*chunit*sin(changle*!dtor),$
            /device,/to_data)
          XYOUTS, xyzch[0],xyzch[1], $
                  time_string(tdbl[0],tformat='hh:mm')+'!C'+scname, $
                  SIZE=!P.CHARSIZE*chscale,orientation=changle,color=trace_color, $
                  charthick=charthick
          
          xch0 = x[N_ELEMENTS(tdbl)-1] & ych0 = y[N_ELEMENTS(tdbl)-1]
          devc = convert_coord(xch0,ych0,/data,/to_device)
          xyzch = convert_coord(devc[0]+dr*chsz*chunit*cos(changle*!dtor),$
            devc[1]+dr*chsz*chunit*sin(changle*!dtor),$
            /device,/to_data)
          XYOUTS, xyzch[0],xyzch[1], $
                  time_string(tdbl[N_ELEMENTS(tdbl)-1],tformat='hh:mm'), $
                  SIZE=!P.CHARSIZE*chscale,orientation=changle,color=trace_color, $
                  charthick=charthick

        endif
        
        ;Draw the footprint at the time given by plottime keyword
        if tp gt 0 and keyword_set(draw_plottime_fp) then begin
          
          if ~keyword_set(fp_time) then fp_time = tp 
          if keyword_set(fp_psym) then fppsym=fp_psym else fppsym=5
          if keyword_set(fp_symsize) then fpsymsz=fp_symsize else fpsymsz=2
          if keyword_set(fp_symthick) then fpsymthick=fp_symthick else fpsymthick=2
          if keyword_set(fp_color) then fpcol=fp_color else fpcol=!p.color
          
          px = [-1.0, -0.2,-0.2, 0.2,0.2,1.0,1.0,0.2,0.2,-0.2,-0.2,-1.0]
          py= [0.7,0.7,1.0,1.0,0.7, 0.7, -0.7,-0.7,-1.0,-1.0,-0.7,-0.7]
          USERSYM, px,py,  /FILL

          
          idx = nn( tdbl_clip, fp_time )
          print, 'tp = ',time_string(fp_time)
          print, 'tdbl_clip[idx]= ',time_string(tdbl_clip[idx])
          plots, phi_clip[idx], lat_clip[idx], $
            psym = fppsym, $
            symsize = fpsymsz, $
            thick = fpsymthick, color = fpcol
          
          
        endif
        

;;;; Plot end
    
  







  timespan, tr_orig   ;Restore the original time range 

  return
end
