;+
;	PROCEDURE overlay_map_sdfit
;
; :DESCRIPTION:
;    Plot a 2-D scan data of a SD radar on the plot window set up by map_set.
;
; :PARAMS:
;    datvn:   tplot variable names (as strings) to be plotted
;
; :KEYWORDS:
;    time:    Set the time (UNIX time) to plot a 2-D scan for
;    position:  Set the location of the plot frame in the plot window
;    geo_plot:  Set to plot in the geographical coordinates
;    nogscat: Set to prevent the ground scatter data from appearing on the plot
;    notimelabel: Set to prevent the time label from appearing on the plot
;    nocolorscale: Set to surpress drawing the color scale 
;    colorscalepos: Set the position of the color scale in the noraml 
;                   coordinates. Default: [0.85, 0.1, 0.87, 0.45] 
;    pixel_scale: Set a value of range 0.0-1.0 to scale pixels drawn on a 2D map plot
;    charscale: Set a value of font size to write the time label and letters for the color scale
;
; :AUTHOR:
; 	Tomo Hori (E-mail: horit@isee.nagoya-u.ac.jp)
;
; :HISTORY:
; 	2011/01/11: Created
; 	2011/06/15: renamed to overlay_map_sdfit
;
; $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26838 $
;-
PRO get_resized_pixel, lons, lats, ratio, rlons, rlats
  
  ;Check the arguments
  if n_params() ne 5 then return
  if n_elements(lons) ne 4 or n_elements(lats) ne 4 then begin
    rlons = lons & rlats = lats
    return
  endif
  if ratio le 0. or ratio gt 1. then begin
    rlons = lons & rlats = lats
    return
  endif
  
  thes = (90. - lats)*!dtor
  phis = lons*!dtor
  zarr = cos(thes)
  xarr = sin(thes)*cos(phis)
  yarr = sin(thes)*sin(phis)
  xc = mean(xarr) & yc = mean(yarr) & zc = mean(zarr) 
  dx = xarr - xc & dy = yarr - yc & dz = zarr - zc 
  
  x_rs = xc + ratio*dx
  y_rs = yc + ratio*dy
  z_rs = zc + ratio*dz
  nmlz = sqrt( x_rs^2 + y_rs^2 + z_rs^2 ) 
  x_rs /= nmlz & y_rs /= nmlz & z_rs /= nmlz
  
  the_rs = acos( z_rs )
  rlats = 90. - the_rs*!radeg
  rlons = ( atan(y_rs,x_rs)*!radeg + 360. ) mod 360.
  
  return
end

;----------------------------------------------------------
PRO overlay_map_sdfit, datvn, time=time, position=position, $
    erase=erase, clip=clip, geo_plot=geo_plot, coord=coord, $
    nogscat=nogscat, gscatmaskoff=gscatmaskoff, $
    notimelabel=notimelabel, timelabelpos=timelabelpos, $
    timelabelformat=timelabelformat, $
    nocolorscale=nocolorscale, colorscalepos=colorscalepos, $
    charscale=charscale, force_nhemis=force_nhemis, $
    pixel_scale=pixel_scale
    
  ;Initialize SDARN system variable and get the default charsize
  sd_init
  
  ;Size of characters
  if ~keyword_set(charscale) then charscale=1.0
  charsz = !sdarn.sd_polar.charsize * charscale
  
  ;Check argument and keyword
  npar=N_PARAMS()
  IF npar LT 1 THEN RETURN
  IF ~KEYWORD_SET(time) THEN BEGIN
    t0 = !map2d.time
    get_timespan, tr
    IF t0 GE tr[0] AND t0 LE tr[1] THEN time = t0 ELSE BEGIN
      time = (tr[0]+tr[1])/2.  ; Take the center of the designated time range
    ENDELSE
  ENDIF
  
  if size(coord, /type) ne 0 then begin
    map2d_coord, coord 
  endif
  if keyword_set(geo_plot) then !map2d.coord = 0
  
  ;if datvn is the index number for tplot var
  datvn = tnames(datvn)
  IF total(datvn eq '') gt 0 THEN BEGIN
    PRINT, 'Given tplot var(s) does not exist?'
    RETURN
  ENDIF
  
  IF KEYWORD_SET(pixel_scale) then begin
    if pixel_scale le 0. or pixel_scale ge 1. then pixel_scale = 0L 
  ENDIF
  
  ;Loop for processing multiple arguments
  tmp_datvn = datvn
  FOR nv=0L, N_ELEMENTS(tmp_datvn)-1 DO BEGIN
  
    tdatvn = tmp_datvn[nv]
    
    ;get the radar name and the suffix
    stn = STRMID(tdatvn, 3,3)
    suf = STRMID(tdatvn, 0,1,/reverse)
    
    ;Load the data to be drawn and to be used for drawing on a 2-d map
    get_data, tdatvn, data=tmp_d, dl=dl, lim=lim
    ;;if (size(d))[2] ne 8 then get_data, d[0], data=d, dl=dl, lim=lim ;For multi-tplot vars
    
    ;Loop for processing a multi-tplot vars
    FOR n=0L, N_ELEMENTS(tmp_d)-1 DO BEGIN
    
      d = tmp_d[n]
      ;For multi-tplot variable case
      IF (SIZE(d))[2] EQ 1 THEN get_data, tmp_d[n], data=d, dl=dl, lim=lim
      
      ;Get "fill_color" attribute if exists as well as the other 
      ;necessary variables
      str_element, dl, 'fill_color', val=fill_color, success=s
      if s eq 0 then fill_color = -1
      
      get_data, 'sd_'+stn+'_azim_no_'+suf, data=az
      get_data, 'sd_'+stn+'_position_tbl_'+suf, data=tbl
      get_data, 'sd_'+stn+'_scanstartflag_'+suf, data=stflg
      get_data, 'sd_'+stn+'_scanno_'+suf, data=scno
      IF STRLEN(tnames('sd_'+stn+'_echo_flag_'+suf)) GT 6 THEN BEGIN
        get_data, 'sd_'+stn+'_echo_flag_'+suf, data=echflg
      ENDIF ELSE BEGIN
        PRINT, 'Cannot find the echo_flag data, which should be loaded in advance'
        RETURN
      ENDELSE
      
      ;Choose data for the time given by keyword
      idx = nn( scno.x, time_double(time) )
      if scno.y[idx] lt 0 then begin  ; Increment idx if the selected beam is a camp beam (beam_scan=-1).
        for tmp_beamno=idx,idx+24 do if scno.y[tmp_beamno] ge 0 then break
        idx = tmp_beamno
      endif
      bmno = WHERE( scno.y EQ scno.y[idx] )
      
      ;;for debugging
      bm_rng = minmax(bmno)
      PRINT,'====== '+tdatvn+' ======'
      PRINT, '             time by sd_time: '+time_string(time)
      PRINT, 'time range of selected beams: '+time_string(scno.x[bm_rng[0]])+' -- '+time_string(scno.x[bm_rng[1]])
      if time lt scno.x[bm_rng[0]] OR time gt scno.x[bm_rng[1]] then begin
        PRINT, 'sd_time is out of the selected beams. The data NOT DRAWN!'
        continue
      endif
      ;print, 'scan no: ',scno.y[idx]
      ;print, 'beam no:', bmno
      ;print, 'scan time: '+time_string(min(scno.x[bmno]))+' -- '+time_string(max(scno.x[bmno]))
      ;;
      
      ;Set the range of the plotted values
      str_element, lim, 'zrange', val, success=s
      IF s EQ 1 THEN valrng = val ELSE valrng=[-1000.,1000]
      
      ;Set color level for contour
      clmax = !d.table_size-1
      clmin = 8L
      cnum = clmax-clmin
      
      
      ;Set the plot position
      pre_position = !p.position
      IF KEYWORD_SET(position) THEN BEGIN
        !p.position = position
      ENDIF ELSE position = !p.position
      
      ;Set the lat-lon canvas
      ;sd_map_set, erase=erase
      
      ;Set the SD color table
      ;loadct_sd, 44, previous_ct=prevct
      
      ;Draw the data
      FOR i=0L, N_ELEMENTS(bmno)-1 DO BEGIN
      
        bn = bmno[i]
        valarr = REFORM(d.y[bn, *, 0])
        echflgarr = REFORM(echflg.y[bn,*])
        rgmax = N_ELEMENTS(valarr)
        azno = az.y[bn]
        tblidx = MAX(WHERE(tbl.x LE d.x[bn], cnt))
        IF tblidx EQ -1 THEN BEGIN
          PRINT, 'beam time does not fall in any time range of the position table!'
          ;loadct2, prevct ;Resotre the original color table before returing
          RETURN
        ENDIF
        pos = REFORM(tbl.y[tblidx,*,azno:(azno+1),*])
        
        ;For plotting in GEO
        pos_plt = pos
        
        ;Convert to AACGM
        IF ~KEYWORD_SET(geo_plot) and !map2d.coord eq 1 THEN BEGIN
          ts = time_struct(time)
          year = ts.year & yrsec = LONG((ts.doy-1)*86400. + ts.sod)
          glat = REFORM(pos[*,*,1]) & glon = REFORM((pos[*,*,0]+360.) MOD 360.)
          hgt = glat & hgt[*,*] = 400.
          year_arr = LONG(glat) & year_arr[*,*] = year
          yrsec_arr= LONG(glat) & yrsec_arr[*,*] = yrsec
          aacgmconvcoord, glat,glon,hgt, mlat,mlon,err,/TO_AACGM
          if (size(mlat))[0] eq 0 then begin ; For Unix ver. AACGM DLM bug 
            mlat = reform(mlat, n_elements(glat[*,0]), n_elements(glat[0,*]) )
            mlon = reform(mlon, n_elements(glat[*,0]), n_elements(glat[0,*]) )
          endif
          mlt_arr = aacgmmlt( year_arr, yrsec_arr, mlon )
          if (size(mlt_arr))[0] eq 0 then begin ; For Unix ver. AACGM DLM bug 
            mlt_arr = reform(mlt_arr, n_elements(mlon[*,0]), n_elements(mlon[0,*]) )
          endif
          plt_lon = ( (mlt_arr + 24.) MOD 24. ) * 180./12.
          
          ;to draw a fan plot forcibly on the N hemis
          if keyword_set(force_nhemis) then mlat=abs(mlat)
          
          pos_plt = pos ;replicate as an array with same numbers of elements
          pos_plt[*,*,0] = plt_lon
          pos_plt[*,*,1] = mlat
        ENDIF
        
        FOR j=0, rgmax-1 DO BEGIN
          val = valarr[j]
          IF ~FINITE(val) THEN CONTINUE ;Skip drawing for NaN
          
          ;Color level for val
          clvl = clmin + cnum*(val-valrng[0])/(valrng[1]-valrng[0])
          clvl = (clvl > clmin)
          clvl = (clvl < (clmax-1) ) ; clmin <= color level <= clmax-1
          IF FIX(echflgarr[j]) ne 1 AND strpos(tdatvn,'_pwr') lt 0 $
            AND strpos(tdatvn,'spec_width') lt 0 THEN BEGIN
            ;ground echo case
            IF KEYWORD_SET(nogscat) THEN CONTINUE ;skip plotting if nogscat keyword i set
            if ~keyword_set(gscatmaskoff) then begin
              if fill_color ge 0 then clvl = fill_color else clvl=5 
            endif
          ENDIF
          
          ;Lon and Lat for a square to be filled
          lon = [ pos_plt[j,0,0], pos_plt[j,1,0], pos_plt[j+1,1,0], pos_plt[j+1,0,0] ]
          lat = [ pos_plt[j,0,1], pos_plt[j,1,1], pos_plt[j+1,1,1], pos_plt[j+1,0,1] ]
          
          
          if keyword_set(pixel_scale) then begin
            get_resized_pixel, lon, lat, pixel_scale, rlons, rlats
            lon = rlons
            lat = rlats
          endif
          
          ;Draw the pixel for a range gate in a beam 
          POLYFILL, lon, lat, color=clvl  
          
        ENDFOR ; for j
        
      ENDFOR ; for i
      
    ENDFOR ;End of the loop for multi-tplot var
    
  ENDFOR ;End of the loop for multi arguments
  
  
  ;Time label
  IF ~KEYWORD_SET(notimelabel) THEN BEGIN
    t = time
    if keyword_set(timelabelpos) then begin ;Customizable by user
      x = !x.window[0] + (!x.window[1]-!x.window[0])*timelabelpos[0] 
      y = !y.window[0] + (!y.window[1]-!y.window[0])*timelabelpos[1]
    endif else begin  ;Default position
      x = !x.window[0]+0.02 & y = !y.window[0]+0.02
    endelse
    
    if ~keyword_set(timelabelformat) then timelabelformat = 'hh:mm'
    tstr = time_string(t, tfor=timelabelformat)+' UT'
    XYOUTS, x, y, tstr, /normal, $
      font=1, charsize=charsz*2.5
  ENDIF
  
  ;Color scale
  if ~keyword_set(nocolorscale) then begin
    str_element, lim, 'ztitle', val=ztitle, success=s
    if s eq 0 then ztitle = ''
    str_element, lim, 'zrange', val=zrange, success=s
    if s eq 0 then zrange = [-1000,1000]
    str_element, lim, 'zticklen', val=yticklen, success=s 
    if s then exstr = { yticklen: yticklen } else exstr = { zticklen: 0.3 } 
    if keyword_set(colorscalepos) then begin
      cp = colorscalepos
      x0 = !x.window[0] & xs = !x.window[1]-!x.window[0]
      y0 = !y.window[0] & ys = !y.window[1]-!y.window[0]
      cspos= [ x0 + xs * cp[0], $
               y0 + ys * cp[1], $
               x0 + xs * cp[2], $
               y0 + ys * cp[3] ]
    endif else begin
      cspos = [0.85,0.1,0.87,0.45]
    endelse
    
    pre_yticklen = !y.ticklen
    !y.ticklen = 0.25
    draw_color_scale, range=zrange,$
      pos=cspos,$
      title=ztitle, charsize=charsz*0.7, _extra=exstr 
    !y.ticklen = pre_yticklen
    
  endif
  
  
  ;Resotre the original plot position
  IF ~KEYWORD_SET(pre_position) THEN pre_position=0
  !p.position = pre_position
  
  ;Normal end
  RETURN
  
END

