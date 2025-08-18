PRO overlay_map_sdfov, site=site, force_nhemis=force_nhemis, $
    geo_plot=geo_plot, coord=coord, linestyle=linestyle, beams=beams, linecolor=linecolor, $
    linethick=linethick, draw_beamnum=draw_beamnum, $
    rgrange=rgrange, pixelonly=pixelonly  
    
  ;Set the list of the available sites
    valid_sites = [ 'ade', 'adw', 'bks', 'bpk', 'cly', 'cve', 'cvw', 'dce', 'fhe', $
    'fhw', 'fir', 'gbr', 'hal', 'han', 'hok', 'hkw', 'inv', 'kap', 'ker', 'kod', $
    'ksr', 'mcm', 'pgr', 'pyk', 'rkn', 'san', 'sas', 'sps', 'sto', 'sye', $
    'sys', 'tig', 'unw', 'wal', 'zho' ]
  
  ;Check the site name
  IF ~KEYWORD_SET(site) THEN BEGIN
    PRINT, 'Keyword SITE should be given'
    RETURN
  ENDIF
  stns = ssl_check_valid_name( site, valid_sites, /ignore_case, /include_all )
  IF STRLEN(stns[0]) EQ 0 THEN BEGIN
    PRINT, 'No valid radar name in sites!'
    PRINT, 'Data currently available: ',valid_sites
    RETURN
  ENDIF
  
  if size(coord, /type) ne 0 then begin
    map2d_coord, coord 
  endif
  if keyword_set(geo_plot) then !map2d.coord = 0
  
  ;The loop to draw fovs of multiple stations
  FOR i=0, N_ELEMENTS(stns)-1 DO BEGIN
    stn = stns[i]
    ptbl_vn = (tnames('sd_'+STRLOWCASE(stn)+'_position_tbl_?'))[0]
    IF STRLEN(ptbl_vn) LT 10 THEN CONTINUE
    
    
    ;Load the position table
    get_data, ptbl_vn,data=d
    glat=REFORM(d.y[0,*,*,1])  ;--> array size [76,17]
    glon=REFORM(d.y[0,*,*,0])
    alt = glat & alt[*] = 400 ;km
    
    IF ~KEYWORD_SET(geo_plot) and !map2d.coord eq 1 THEN BEGIN
      aacgmconvcoord,glat,glon,alt,mlat,mlon,err,/TO_AACGM
      mlon = (mlon + 360.) MOD 360.
      ts = time_struct(!map2d.time)
      yrsec = LONG( alt )
      yrsec[*] = LONG((ts.doy-1)*86400L + ts.sod)
      yr = yrsec & yr[*] = ts.year
      
      tmlt = aacgmmlt(yr, yrsec, mlon)
      tmlt = ( (tmlt + 24. ) MOD 24. ) /24.*360.  ;[deg]
      
      ;Forcibly draw in the northern hemisphere
      if keyword_set(force_nhemis) then mlat = abs(mlat)
      
    ENDIF ELSE BEGIN
      mlat = glat & tmlt = glon
    ENDELSE
    
    n_rg = N_ELEMENTS(mlat[*,0])-1
    n_az = N_ELEMENTS(mlat[0,*])-1
    
    PLOTS,tmlt[0,0:n_az],mlat[0,0:n_az], linestyle=linestyle, color=linecolor, $
      thick=linethick
    PLOTS,tmlt[0:n_rg,n_az],mlat[0:n_rg,n_az], linestyle=linestyle, color=linecolor, $
      thick=linethick
    PLOTS,tmlt[n_rg,0:n_az],mlat[n_rg,0:n_az], linestyle=linestyle, color=linecolor, $
      thick=linethick
    PLOTS,tmlt[0:n_rg,0],mlat[0:n_rg,0], linestyle=linestyle, color=linecolor, $
      thick=linethick
    
    ;Draw selected beams
    if total(size(beams)) gt 0 then begin
      ;;print, beams
      for n=0L, n_elements(beams)-1 do begin
        bm = beams[n]
        if bm ge n_az or bm lt 0 then continue
        if ~keyword_set(pixelonly) then begin
          PLOTS,tmlt[0:n_rg,bm],mlat[0:n_rg,bm], linestyle=linestyle, color=linecolor, thick=linethick
          PLOTS,tmlt[0:n_rg,bm+1],mlat[0:n_rg,bm+1], linestyle=linestyle, color=linecolor, thick=linethick
        endif
        
        if keyword_set(draw_beamnum) then begin
          xyouts,  $
            (tmlt[n_rg,bm]+tmlt[n_rg,bm+1])/2, $
            (mlat[n_rg,bm]+mlat[n_rg,bm+1])/2, $
            'bm'+string(bm,'(I2.2)'), $
            alignment=0.5
          endif
          
          if keyword_set(rgrange) then begin
            rgn = rgrange
            if n_elements(rgn) eq 1 then begin
              if min(rgn) ge 0 and max(rgn) lt n_rg then begin
                PLOTS,tmlt[rgn,bm:(bm+1)],mlat[rgn, bm:(bm+1)], linestyle=linestyle, color=linecolor, thick=linethick
                PLOTS,tmlt[rgn+1,bm:(bm+1)],mlat[rgn+1, bm:(bm+1)], linestyle=linestyle, color=linecolor, thick=linethick
                PLOTS,tmlt[rgn:(rgn+1), bm], mlat[rgn:(rgn+1), bm], linestyle=linestyle, color=linecolor, thick=linethick
                PLOTS,tmlt[rgn:(rgn+1), bm+1], mlat[rgn:(rgn+1), bm+1], linestyle=linestyle, color=linecolor, thick=linethick
              endif
            endif
            if n_elements(rgn) eq 2 then begin
              rgn = minmax(rgn)
              if rgn[0] ge 0 and rgn[1] lt n_rg then begin
                for ii = rgn[0], rgn[1] do begin
                  PLOTS,tmlt[ii, bm:(bm+1)],mlat[ii, bm:(bm+1)], linestyle=linestyle, color=linecolor, thick=linethick
                  PLOTS,tmlt[ii+1, bm:(bm+1)],mlat[ii+1, bm:(bm+1)], linestyle=linestyle, color=linecolor, thick=linethick
                  PLOTS,tmlt[ii:(ii+1), bm], mlat[ii:(ii+1), bm], linestyle=linestyle, color=linecolor, thick=linethick
                  PLOTS,tmlt[ii:(ii+1), bm+1], mlat[ii:(ii+1), bm+1], linestyle=linestyle, color=linecolor, thick=linethick
                endfor
              endif
            endif

          endif ; if keyword_set(rgrange) then begin
          
      endfor
    endif
    
  ENDFOR
  
  RETURN
END
