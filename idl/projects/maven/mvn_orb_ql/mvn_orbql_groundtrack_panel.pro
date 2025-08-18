;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mvn_orbql_groundtrack_panel.pro
;
; Procedure to create a 2D groundtrack plot for a MAVEN spaecraft
; trajectory. It automatically includes a map of crustal Br from MGS.
;
; Syntax:
;      trange = mvn_orbql_groundtrack_panel, trange, res
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
;      3. mvn_orbql_colorscale.pro - Dave Brain version of bytscl.pro
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
pro mvn_orbql_groundtrack_panel, $
   trange=trange, res=res, $
   terminator=terminator, $
   showtermrange = showtermrange, $
   periapsis=periapsis, interest_point=interest_point, ticks=ticks,$
   msofields = msofields,$
   symsize = ss, charsize = cs, noerase=noerase,$
   orbitcolortable=orbitcolortable,$
   overlaycolortable=overlaycolortable,$
   reverseoverlaycolortable=reverseoverlaycolortable


  
;;; Parameters
  Rm = 3390.


;;; Get passed keywords  
  if n_elements(ss) eq 0 then ss = 1
  if n_elements(cs) eq 0 then cs = 1
  if n_elements(noerase) eq 0 then noerase = 0
  if n_elements(trange) eq 0 then get_timespan, trange
  if n_elements(res) eq 0 then res = 60d0
  if keyword_set(showtermrange) then terminator = 1


  if not keyword_set(orbitcolortable) then orbitcolortable = 63

  if not keyword_set(overlaycolortable) then overlaycolortable = 70
  if not keyword_set(reverseoverlaycolortable) then reverseoverlaycolortable = 1


;;; Check for ephemeris at proper time resolution
;;;  and load it if it isn't already there and perfect
;;;  Along the way, get the lon and lat in MSO coordinates
  names = tnames()
  lon_present = where(names eq 'mvn_lon')
  lat_present = where(names eq 'mvn_lat')
  if lon_present[0] eq -1 or $
     lat_present[0] eq -1 then mvn_barebones_eph, trange, res
  get_data, 'mvn_lon', time, lon
  if time[1] - time[0] ne res or $
     time[0] gt (trange[0] + 60*5) or $
     time[-1] lt (trange[1] - 60*5) then begin
     mvn_barebones_eph, trange, res
     get_data, 'mvn_lon', time, lon
  endif
  get_data, 'mvn_lat', time, lat



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
  ; ctload, 0
  loadct2, 0
  plot, [0], [0], /nodata, /iso, $
        xrange = [0,360], xstyle = 1, xticks=6, $
        xtitle = 'East Longitude', $
        yrange = [-90,90], ystyle = 1, yticks=4, $
        ytitle = 'Latitude', $
        xthick = 2, ythick = 2, $
        charsize = cs, noerase=noerase

    if keyword_set(msofields) then begin

        ;;; Plot the crustal field map
        ; loadct2, overlaycolortable, reverse=reverseoverlaycolortable, rgb=rgb
        initct, overlaycolortable, /reverse
          ; ctload, 22, /brewer, /reverse, rgb=rgb
          ; rgb[255,*] = 255
          ; tvlct, rgb[*,0], rgb[*,1], rgb[*,2]
          ; stop
        mvn_orbql_overlay_map, msofields.mapcolor_groundtrack
        ; stop

        ; if !d/name eq 'x' then

    endif

  ; loadct, 0
  loadct2, 0


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
     if keyword_set(showtermrange) eq 1 then loadct2, orbitcolortable
     plots, lonterm, latterm, psym=mvn_orbql_symcat(16), symsize=.2, color=135
     plots, lonsubsolar, latsubsolar, psym=mvn_orbql_symcat(46), symsize=ss*2, color=135
  endif
  if keyword_set(showtermrange) then begin
     loadct2, orbitcolortable
     plots, startlonterm, startlatterm, $
            psym=mvn_orbql_symcat(16), symsize=.2, color=20
     plots, startlonsubsolar, startlatsubsolar, $
            psym=mvn_orbql_symcat(46), symsize=ss*2, color=20
     plots, stoplonterm, stoplatterm, $
            psym=mvn_orbql_symcat(16), symsize=.2, color=250
     plots, stoplonsubsolar, stoplatsubsolar, $
            psym=mvn_orbql_symcat(46), symsize=ss*2, color=250
  endif


;;; Shade shadowed region?
  ; ctload, 0
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

;;; Colorscale data
  color = mvn_orbql_colorscale( time, mindat=min(trange), maxdat=max(trange), $
                      mincol=20, maxcol=250 )

;;; Plot data
  loadct2, orbitcolortable
  plots, lon, lat, psym=mvn_orbql_symcat(14), color=color, symsize=ss
  
;;; Plot tick marks and periapsis location
  ; ctload, 0
  loadct2, 0

  if keyword_set(ticks) then plots, ticks.lon, ticks.lat,$
     psym=mvn_orbql_symcat(ticks.m), symsize=ss * ticks.ss

  if keyword_set(periapsis) then plots, periapsis.lon, periapsis.lat,$
     psym=mvn_orbql_symcat(periapsis.m), symsize=ss * periapsis.ss

  if keyword_set(interest_point) then plots, interest_point.lon, interest_point.lat,$
     psym=mvn_orbql_symcat(interest_point.m), symsize=ss * interest_point.ss

;;; Redraw axes
  plot, [0], [0], /nodata, /iso, /noerase, $
        xrange = [0,360], xstyle = 1, xticks=6, $
        xtitle = 'East Longitude', $
        yrange = [-90,90], ystyle = 1, yticks=4, $
        ytitle = 'Latitude', $
        xthick = 2, ythick = 2, $
        charsize = cs

   !p.background = 255
   !p.color = 0
   
   !p.multi = [0,0,0,0,0]
   !p.region = [0,0,0,0]
   !p.position = [0,0,0,0]
   
   !p.charsize = 1
   !p.charthick = 1
    

end
