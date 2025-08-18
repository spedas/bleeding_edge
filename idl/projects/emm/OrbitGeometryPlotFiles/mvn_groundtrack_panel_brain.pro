;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mvn_groundtrack_panel_brain.pro
;
; Procedure to create a 2D groundtrack plot for a MAVEN spaecraft
; trajectory. It automatically includes a map of crustal Br from MGS.
;
; Syntax:
;      trange = mvn_groundtrack_panel_brain, trange, res
;
; Inputs:
;      trange            - 2-elelment timerange over which to plot the
;                          trajectory
;
;      res               - The time resolution to use when plotting
;
;      terminator        - Boolean: Indicate the location of the
;                          terminator and subsolar point at the
;                          midpoint of the timerange, and shade the
;                          nightside. Default = not set
;
;      showtermrange     - Boolean: Indicate the *range* in terminator
;                          location over the trange passed to the
;                          routine. Automatically sets /terminator,
;                          and adds terminator lines and subsolar
;                          locations for the start and stop of the
;                          timerange. Default = not set
;
;      showperiapsis     - Boolean: Indicate the location of
;                          periapsis. Default = not set
;
;      showticks         - Indicate regular intervals (centered on
;                          periapsis) along the trajectory. Default =
;                          not set
;
;      tickinterval      - The interval at which to show ticks, in
;                          seconds. Default = 600
;
;      symsize           - Symbol size to use for the
;                          trajectory. Sizes of periapsis, interval
;                          ticks, crustal fields all scale from
;                          this. Default = 1.
;
;      charsize          - Character size to use for plot
;                          axes. Default = 1
;
;      noerase           - Boolean, default = 0. Setting to 1
;                          indicates that and plot currently on the
;                          plot device should not be erased.
;
; Dependencies:
;      1. Berkeley MAVEN software
;      2. ctload.pro - routine from David Fanning (coyote) to load
;                      color tables, including Brewer colors.
;      3. colorscale.pro - Dave Brain version of bytscl.pro
;      4. Map of crustal field Br - edit line ~116 to point to the
;                                   relevant location on your machine
;
; Comments:
;      1. This was developed for use with a single orbit
;         trajectory. I'm not sure how it would work with
;         something larger.
;      2. This routine acts on tplot variables loaded using
;         mvn_load_eph_brain.pro. If it doesn't find them, it
;         will load them.
;
; Dave Brain
; 12 January, 2017 -Initial version
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;-
pro mvn_groundtrack_panel_brain, $
   trange=trange, res=res, $
   terminator=terminator, crustalfields = crustalfields,$
   showtermrange = showtermrange, $
   showperiapsis = showperiapsis, $
   showticks = showticks, tickinterval = tickinterval, $
   symsize = ss, charsize = cs, $
   noerase=noerase, overlay = overlay

  
;;; Parameters
  Rm = 3390.


;;; Get passed keywords  
  if n_elements(ss) eq 0 then ss = 1
  if n_elements(cs) eq 0 then cs = 1
  if n_elements(noerase) eq 0 then noerase = 0
  if n_elements(trange) eq 0 then get_timespan, trange
  if n_elements(res) eq 0 then res = 60d0
  if n_elements(tickinterval) eq 0 then tickinterval = 600d0
  if keyword_set(showticks) then showperiapsis = 1
  if keyword_set(showtermrange) then terminator = 1


;;; Check for ephemeris at proper time resolution
;;;  and load it if it isn't already there and perfect
;;;  Along the way, get the lon and lat in MSO coordinates
  names = tnames()
  lon_present = where(names eq 'mvn_lon')
  lat_present = where(names eq 'mvn_lat')
  if lon_present[0] eq -1 or $
     lat_present[0] eq -1 then mvn_load_eph_brain, trange, res
  get_data, 'mvn_lon', time, lon
  if time[1] - time[0] ne res or $
     time[0] gt trange[0] or $
     time[-1] lt trange[1] then begin
     mvn_load_eph_brain, trange, res
     get_data, 'mvn_lon', time, lon
  endif
  get_data, 'mvn_lat', time, lat


;;; Get the crustal fields

  if keyword_set (crustalfields) then begin
     restore, '~/work/mgs/magdata/old_magfiles/br_360x180_pc.sav'
     mapcolor = colorscale( br, mindat=-50, maxdat=50, mincol=7, maxcol=254 )
     tmp = where(br eq 0, tmpcnt)
     if tmpcnt ne 0 then mapcolor[tmp] = 255
  endif 

  if keyword_set (overlay) then begin
     if overlay.log eq 0 then begin
        data = overlay.data
        range = overlay.range
     endif else begin
        data = alog10 (overlay.data)
        range = alog10 (overlay.range)
     endelse
     mapcolor = $
        colorscale(data, mindat=Range [0], Maxdat = range [1], $
                   mincol=7, maxcol=254 )
; Choose a color for nan
     nan = where (finite (data) eq 0)
     if nan [0] ne -1 then mapcolor [nan] = 230
  endif
  


;;; Get the terminator and subsolar point
  if keyword_set(terminator) then begin
     ang = findgen(360) * !dtor
     y = Rm * cos(ang)
     z = Rm * sin(ang)
     ans = spice_vector_rotate( transpose([[y*0.],[y],[z]]), $
                                replicate(mean(trange),360), $
                                'MAVEN_MSO', 'IAU_MARS' )
     xterm = ans[0,*]
     yterm = ans[1,*]
     zterm = ans[2,*]
     lonterm = atan(yterm,xterm) * !radeg
     lonterm = (lonterm + 360.) mod 360.
     latterm = atan( zterm / sqrt(xterm^2. + yterm^2.) ) * !radeg
     latterm = reform(latterm)
     lonterm = reform(lonterm)
     
     ans = spice_vector_rotate( [Rm,0,0], mean(trange), $
                                'MAVEN_MSO', 'IAU_MARS' )
     lonsubsolar = atan(ans[1],ans[0]) * !radeg
     lonsubsolar = (lonsubsolar + 360.) mod 360.
     latsubsolar = atan( ans[2] / sqrt(ans[0]^2. + ans[1]^2.) ) * !radeg
  endif


;;; Get the terminator and subsolar point for start and stop
  if keyword_set(showtermrange) then begin
     ang = findgen(360) * !dtor
     y = Rm * cos(ang)
     z = Rm * sin(ang)
     ans = spice_vector_rotate( transpose([[y*0.],[y],[z]]), $
                                replicate(trange[0],360), $
                                'MAVEN_MSO', 'IAU_MARS' )
     xterm = ans[0,*]
     yterm = ans[1,*]
     zterm = ans[2,*]
     startlonterm = atan(yterm,xterm) * !radeg
     startlonterm = (startlonterm + 360.) mod 360.
     startlatterm = atan( zterm / sqrt(xterm^2. + yterm^2.) ) * !radeg
     startlatterm = reform(startlatterm)
     startlonterm = reform(startlonterm)
     
     ans = spice_vector_rotate( [Rm,0,0], trange[0], $
                                'MAVEN_MSO', 'IAU_MARS' )
     startlonsubsolar = atan(ans[1],ans[0]) * !radeg
     startlonsubsolar = (startlonsubsolar + 360.) mod 360.
     startlatsubsolar = atan( ans[2] / sqrt(ans[0]^2. + ans[1]^2.) ) * !radeg

     ans = spice_vector_rotate( transpose([[y*0.],[y],[z]]), $
                                replicate(trange[1],360), $
                                'MAVEN_MSO', 'IAU_MARS' )
     xterm = ans[0,*]
     yterm = ans[1,*]
     zterm = ans[2,*]
     stoplonterm = atan(yterm,xterm) * !radeg
     stoplonterm = (stoplonterm + 360.) mod 360.
     stoplatterm = atan( zterm / sqrt(xterm^2. + yterm^2.) ) * !radeg
     stoplatterm = reform(stoplatterm)
     stoplonterm = reform(stoplonterm)
     
     ans = spice_vector_rotate( [Rm,0,0], trange[1], $
                                'MAVEN_MSO', 'IAU_MARS' )
     stoplonsubsolar = atan(ans[1],ans[0]) * !radeg
     stoplonsubsolar = (stoplonsubsolar + 360.) mod 360.
     stoplatsubsolar = atan( ans[2] / sqrt(ans[0]^2. + ans[1]^2.) ) * !radeg
  endif










  
  

;;; Set up for the plot
  !p.background = 255
  !p.color = 0
  
      
;;; Make the plot axes
  loadct2, 0
  plot, [0], [0], /nodata, /iso, $
        xrange = [0,360], xstyle = 1, xticks=6, $
        xtitle = 'East Longitude', $
        yrange = [-90,90], ystyle = 1, yticks=4, $
        ytitle = 'Latitude', $
        xthick = 2, ythick = 2, $
        charsize = cs, noerase=noerase


;;; Plot the crustal field map
  if keyword_set (crustalfields) then loadct2, 70, /reverse, rgb=rgb else $
     loadct2, overlay.color_table,rgb=rgb
  rgb[255,*] = 255
  tvlct, rgb[*,0], rgb[*,1], rgb[*,2]
  overlaid, mapcolor
  loadct, 0


;;; Plot the latitude lines
  lats = [ -45, 0, 45 ]
  for i = 0, n_elements(lats)-1 do begin
     oplot, [0,360], lats[i]*[1,1]
  endfor                        ; i


;;; Plot the longitude lines
  lons = [ 60, 120, 180, 240, 300 ]
  for i = 0, n_elements(lons)-1 do begin
     oplot, lons[i] * [1,1], [-90,90]
  endfor                        ; i


;;; Plot terminator and subsolar point
  if keyword_set(terminator) then begin
     if keyword_set(showtermrange) eq 1 then loadct2, 63
     plots, lonterm, latterm, psym=symcat(16), symsize=.2, color=135
     plots, lonsubsolar, latsubsolar, psym=symcat(46), symsize=ss*2, color=135
  endif
  if keyword_set(showtermrange) then begin
     loadct2, 63
     plots, startlonterm, startlatterm, $
            psym=symcat(16), symsize=.2, color=20
     plots, startlonsubsolar, startlatsubsolar, $
            psym=symcat(46), symsize=ss*2, color=20
     plots, stoplonterm, stoplatterm, $
            psym=symcat(16), symsize=.2, color=250
     plots, stoplonsubsolar, stoplatsubsolar, $
            psym=symcat(46), symsize=ss*2, color=250
  endif


;;; Shade shadowed region?
  if keyword_set (crustalfields) then begin
     loadct2, 0
     ord = sort(lonterm)
     lonterm = lonterm[ord]
     latterm = latterm[ord]
     ans = interpol( latterm, lonterm, lonsubsolar )
     if ans gt latsubsolar then begin
        polyfill, color=100, /line_fill, orientation=45, spacing=0.25, $
                  [lonterm,360,0], [latterm,90,90]
     endif else begin
        polyfill, color=100, /line_fill, orientation=45, spacing=0.25, $
                  [lonterm,360,0], [latterm,-90,-90]
     endelse
  endif
  

;;; Colorscale data
  color = colorscale( time, mindat=min(trange), maxdat=max(trange), $
                      mincol=20, maxcol=250 )
  

;;; Plot data
  loadct, 63
  plots, lon, lat, psym=symcat(14), color=color, symsize=ss


  
;;; Get periapsis location
  if keyword_set(showperiapsis) then begin
     get_data, 'mvn_eph_geo', time, geo
     peritimes = dindgen( trange[1] - trange[0] + 1 ) + trange[0]
     perixdat = spline( time, geo[0,*], peritimes )
     periydat = spline( time, geo[1,*], peritimes )
     perizdat = spline( time, geo[2,*], peritimes )
     perirad = sqrt( perixdat^2 + periydat^2 + perizdat^2 )
     minrad = min(perirad,periind)
     perixdat = perixdat[periind]
     periydat = periydat[periind]
     perizdat = perizdat[periind]
     geo_sph = cv_coord( from_rect=[perixdat, periydat, perizdat], $
                         /to_sphere, /double )
     perilon = ( reform( geo_sph[0,*] ) * !radeg + 360. ) mod 360.
     perilat = reform( geo_sph[1,*] ) * !radeg
  endif


  
;;; Get locations of tick marks and plot
  if keyword_set(showticks) then begin
     ;; Get times to show
     peritime = peritimes[periind]
     timeinterval = trange[1]-trange[0]
     ticktimes = [peritime]
     curtime = peritime - tickinterval
     while curtime gt trange[0] do begin
        ticktimes = [ curtime, ticktimes ]
        curtime -= tickinterval
     endwhile
     curtime = peritime + tickinterval
     while curtime lt trange[1] do begin
        ticktimes = [ ticktimes, curtime ]
        curtime += tickinterval
     endwhile
     tickxdat = spline( time, geo[0,*], ticktimes )
     tickydat = spline( time, geo[1,*], ticktimes )
     tickzdat = spline( time, geo[2,*], ticktimes )
     geo_sph = cv_coord( from_rect=transpose( [ [tickxdat], $
                                                [tickydat], $
                                                [tickzdat] ] ), $
                         /to_sphere, /double )
     ticklon = ( reform( geo_sph[0,*] ) * !radeg + 360. ) mod 360.
     ticklat = reform( geo_sph[1,*] ) * !radeg
  endif


  
;;; Plot tick marks and periapsis location
  loadct2, 0
  plots, ticklon, ticklat, psym=symcat(14), symsize=ss/2.
  plots, perilon, perilat, psym=symcat(34), symsize=ss*1.5
                               
   
   
;;; Redraw axes
  loadct, 0
  plot, [0], [0], /nodata, /iso, /noerase, $
        xrange = [0,360], xstyle = 1, xticks=6, $
        xtitle = 'East Longitude', $
        yrange = [-90,90], ystyle = 1, yticks=4, $
        ytitle = 'Latitude', $
        xthick = 2, ythick = 2, $
        charsize = cs
  


;;; Clean up
   cleanup

    

end
