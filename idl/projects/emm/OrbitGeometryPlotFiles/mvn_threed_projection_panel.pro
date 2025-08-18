;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mvn_threed_projection_panel_brain.pro
;
; Procedure to create a 2D orbit projection plot for a MAVEN spaecraft
; trajectory. 
;
; Syntax:
;      trange = mvn_orbproj_panel_brain, trange, res, /xy
;
; Inputs:
;      trange            - 2-elelment timerange over which to plot the
;                          trajectory
;
;      res               - The time resolution to use when plotting
;
;      [xy]range         - 2-element bounds for the plot, in
;                          Rm. Default = [-3,3]
;
;      obstime           - The time to use when orienting Mars with
;                          respect to the Sun. Default = mean(trange)
;
;      obspos            - explicitly defined the observer's
;                          position in MSO coordinates
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
;      4. Map of crustal field Br - edit line ~178 to point to the
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
pro mvn_threed_projection_panel, $
   trange=trange, res=res, $
   xrange = xrange, yrange = yrange, $
   obstime = obstime, $
   showperiapsis = showperiapsis, $
   showticks = showticks, tickinterval = tickinterval, $
   symsize = ss, noerase = noerase, overlay = overlay, $
   crustalfields = crustalfields,obspos = obspos, $
   orbitcolortable = orbitcolortable

;;; obstime = -1 --> center on midpoint of timerange; default!

;;; Parameters
  Rm = 3390.
  if not keyword_set (orbitcolortable) then orbitcolortable = 63
  

;;; Get passed keywords
  if n_elements(trange) eq 0 then get_timespan, trange
  if n_elements(res) eq 0 then res = 60d0
  if n_elements(xrange) eq 0 then xrange = [-3,3]
  if n_elements(yrange) eq 0 then yrange = [-3,3]
  if n_elements(obstime) eq 0 then obstime = mean(trange)
  if n_elements(ss) eq 0 then ss = 1
  if n_elements(noerase) eq 0 then noerase = 0
  if n_elements(tickinterval) eq 0 then tickinterval = 600d0
  if keyword_set(showticks) then showperiapsis = 1


;;; Check for ephemeris at proper time resolution
;;;  and load it if it isn't already there and perfect
;;;  Along the way, get the S/C posn in MSO coordinates
  names = tnames()
  mso_present = where(names eq 'mvn_eph_mso')
  alt_present = where(names eq 'mvn_alt')
  lon_present = where(names eq 'mvn_lon')
  if mso_present[0] eq -1 or $
     alt_present[0] eq -1 or $
     lon_present[0] eq -1 then mvn_load_eph_brain, trange, res
  get_data, 'mvn_eph_mso', time, mso
  if time[1] - time[0] ne res or $
     time[0] gt trange[0] or $
     time[-1] lt trange[1] then begin
     mvn_load_eph_brain, trange, res
     get_data, 'mvn_eph_mso', time, mso
  endif
  mso /= Rm


;;; Get time of observer, and observer's longitude and latitude in MSO
  if not keyword_set (obspos) then begin
     obsx = spline( time, mso[0,*], obstime )
     obsy = spline( time, mso[1,*], obstime )
     obsz = spline( time, mso[2,*], obstime )
  endif else begin
     obsx = obspos [0]
     OBSy = obspos [1]
     obsz = OBSpos [2]
  endelse

  obssph = cv_coord( from_rect=[obsx, obsy, obsz], /to_sphere, /double )
  obslon = double( reform( obssph[0] ) )
  obslat = double( reform( obssph[1] ) )
  obslon = obslon[0]
  obslat = obslat[0]


;;; Get xdata and ydata for latitude lines, in observer cartesian
  nlat = 5
  ndots = 720.
  xlat = fltarr(ndots, nlat)
  ylat = fltarr(ndots, nlat)
  zlat = fltarr(ndots, nlat)
  for i = 0, nlat-1 do begin
     curlat = ( 180./(nlat+1.) * (i+1) - 90. ) * !dtor
     xtmp = Rm * cos( findgen(ndots) * 360. / ndots * !dtor ) * $
            cos(curlat)
     ytmp = Rm * sin( findgen(ndots) * 360. / ndots * !dtor ) * $
            cos(curlat)
     ztmp = replicate(Rm*sin(curlat),ndots)
     ans = spice_vector_rotate( transpose([[xtmp],[ytmp],[ztmp]]), $
                                replicate(mean(trange),ndots), $
                                'IAU_MARS', $
                                'MAVEN_MSO' )
     obsview, $
        reform(ans[0,*]) / Rm, reform(ans[1,*]) / Rm, reform(ans[2,*]) / Rm, $
        xtmp, ytmp, ztmp, $
        lon = obslon, lat = obslat
     xlat[*,i] = xtmp
     ylat[*,i] = ytmp
     zlat[*,i] = ztmp
  endfor                        ; i

         
;;; Get xdata and ydata for longitude lines, in observer cartesian
  nlon = 8.
  ndots = 720.
  xlon = fltarr(ndots, nlon)
  ylon = fltarr(ndots, nlon)
  zlon = fltarr(ndots, nlon)
  for i = 0, nlon-1 do begin
     curlon = 360. / nlon * i * !dtor
     xtmp = Rm * cos( findgen(ndots) * 360. / ndots * !dtor ) * $
            cos(curlon)
     ytmp = Rm * cos( findgen(ndots) * 360. / ndots * !dtor ) * $
            sin(curlon)
     ztmp = Rm * sin( findgen(ndots) * 360. / ndots * !dtor )
     ans = spice_vector_rotate( transpose([[xtmp],[ytmp],[ztmp]]), $
                                replicate(mean(trange),ndots), $
                                'IAU_MARS', $
                                'MAVEN_MSO' )
     obsview, $
        reform(ans[0,*]) / Rm, reform(ans[1,*]) / Rm, reform(ans[2,*]) / Rm, $
        xtmp, ytmp, ztmp, $
        lon = obslon, lat = obslat
     xlon[*,i] = xtmp
     ylon[*,i] = ytmp
     zlon[*,i] = ztmp
  endfor                        ; i


; if an overlay image is provided
  
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
     if nan [0] ne -1 then mapcolor [nan] = 1
     
     nummaplon = n_elements(overlay.elon)
     nummaplat = n_elements(overlay.lat)
     maplonres = 360./nummaplon
     maplatres = 180./nummaplat
     maplons = findgen(nummaplon) * maplonres + maplonres/2.
     maplats = findgen(nummaplat) * maplatres - 90. + maplonres/2.
     ntotal = nummaplon*1L*nummaplat
; make two-dimensional versions of them, reformed into one dimension
     maplon_2d = reform (maplons# replicate (1,nummaplat), ntotal)
     maplat_2d = reform (maplats##replicate (1,nummaplon), ntotal)
; then  make one-dimensional versions of the 2-D versions
     
     
     xtmp = Rm * cos(maplon_2d*!dtor) * cos(maplat_2d*!dtor)
     ytmp = Rm * sin(maplon_2d*!dtor) * cos(maplat_2d*!dtor)
     ztmp = Rm * sin(maplat_2d*!dtor)
; need to turn them into 1-d before transforming
     xtmp = reform(xtmp, ntotal)
     ytmp = reform (ytmp, ntotal)
     ztmp = reform (ztmp, ntotal)
     ans = spice_vector_rotate( transpose ([[xtmp], [ytmp], [ztmp]]), $
                                replicate (mean(trange),ntotal), $
                                'IAU_MARS', $
                                'MAVEN_MSO' )
     mapx = ans[0,*] / Rm
     mapy = ans[1,*] / Rm
     mapz = ans[2,*] / Rm       ; i
  endif
  
  ;;; Get the crustal fields
  if keyword_set(crustalfields) eq 1 then begin
     path = FILE_DIRNAME(ROUTINE_FILEPATH(), /mark)
     contour_file = path + 'br_contours_Morschhauser_spc_dlat1.0_delon1.0_400km.sav'
     restore, contour_file
; the number of points describing the contours
     np = n_elements (br_contours.elon)
     xtmp = Rm * cos(br_contours.elon*!dtor) * cos(br_contours.lat *!dtor)
     ytmp = Rm * sin(br_contours.elon*!dtor) * cos(br_contours.lat *!dtor)
     ztmp = Rm * sin(br_contours.lat *!dtor)
     ans = spice_vector_rotate(transpose ([[xtmp], [ytmp], [ztmp]]), $
                               replicate (mean(trange),np), $
                               'IAU_MARS', $
                               'MAVEN_MSO' )
     contourx = ans[0,*] / Rm
     contoury = ans[1,*] / Rm
     contourz = ans[2,*] / Rm
      positive_color = 80
      negative_color = 176
      contourcolor = [(br_contours.sign gt 0)*positive_color + $
                      (br_contours.sign lt 0)*negative_color]
       ;scatter_specplot, BR_contours.Elon, BR_contours.LAT, contourcolor, PSY = 3
  endif



;;; Get the trajectory in observer cartesian
  obsview, $
     reform(mso[0,*]), reform(mso[1,*]), reform(mso[2,*]), $
     xtraj, ytraj, ztraj, $
     lon = obslon, lat = obslat

  
;;; Get periapsis location
  if keyword_set(showperiapsis) then begin
     peritimes = dindgen( trange[1] - trange[0] + 1 ) + trange[0]
     perixdat = spline( time, mso[0,*], peritimes )
     periydat = spline( time, mso[1,*], peritimes )
     perizdat = spline( time, mso[2,*], peritimes )
     perirad = sqrt( perixdat^2 + periydat^2 + perizdat^2 )
     minrad = min(perirad,periind)
     obsview, $
        perixdat[periind], periydat[periind], perizdat[periind], $
        perix, periy, periz, $
        lon = obslon, lat = obslat
  endif

  
;;; Get locations of tick marks
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
     tickxdat = spline( time, mso[0,*], ticktimes )
     tickydat = spline( time, mso[1,*], ticktimes )
     tickzdat = spline( time, mso[2,*], ticktimes )
     obsview, $
        reform( tickxdat), reform( tickydat ), reform( tickzdat ), $
        tickx, ticky, tickz, $
        lon = obslon, lat = obslat
  endif

  

;;; Create locations in darkness
  darklonres = 3d
  darklatres = 1d
  numdarklon = 180./darklonres + 1.
  numdarklat = 180./darklatres + 1.
  darklonarr = dindgen(numdarklon) * darklonres + 90d
  darklatarr = dindgen(numdarklat) * darklatres - 90d
  darklon = darklonarr # replicate( 1d, numdarklat )
  darklon[0:*:2] += darklonres/2.
  darklat = replicate( 1d, numdarklon ) # darklatarr
  darkln = reform( darklon, numdarklon*numdarklat )
  darklt = reform( darklat, numdarklon*numdarklat )
  sph_coord = transpose( [ [darkln], [darklt], [darkln] ] )
  sph_coord[2,*] = 1d
  darkcart = cv_coord( from_sphere=sph_coord, $
                       /to_rect, /degrees )
  obsview, $
     reform(darkcart[0,*]), reform(darkcart[1,*]), reform(darkcart[2,*]), $
     xdrk, ydrk, zdrk, $
     lon = obslon, lat = obslat

  
;;; Set up for the plot
   !p.background = 255
   !p.color = 0


;;; Make the plot axes
   loadct, 0
   plot, [0], [0], /nodata, /iso, $
         xrange = xrange, xstyle = 1, $
         yrange = yrange, ystyle = 1, $
         xmargin = [2,2], ymargin = [2,2], $
         xticks = 1, yticks = 1, $
         xminor = 1, yminor = 1, $
         xtickname = replicate(' ',2), $
         ytickname = replicate(' ',2), $
         noerase = noerase



;;; Fill the plot area with gray
   polyfill, color=220, $
             [ xrange, reverse(xrange) ], $
             [ [1,1]*yrange[0], [1,1]*yrange[1] ]


   
;;; Colorscale the trajectory
   trajcolor = colorscale( time, $
                       mindat=min(trange), maxdat=max(trange), $
                       mincol=20, maxcol=250 )

;;; Plot the trajectory below the projection plane
   loadct, orbitcolortable
   cdat = Trajcolor
   ;; Sort it by distance from observer
   ord = sort(ztraj)
   xdat = xtraj[ord]
   ydat = ytraj[ord]
   zdat = ztraj[ord]
   cdat = cdat[ord]
   ;; Get rid of locations obscured by Mars or out of bounds
   keep = where( ( zdat lt 0 and $
                   sqrt(xdat^2. + ydat^2.) gt 1 ) and $
                 xdat gt xrange[0] and xdat lt xrange[1] and $
                 ydat gt yrange[0] and ydat lt yrange[1], keepcnt)
   ;; Display the trajectory
   if keepcnt gt 0 then begin
 
      plots, xdat[keep], ydat[keep], $
             psym=symcat(14), color=cdat[keep], symsize=ss
   endif


;;; Show ticks as black diamonds (below the projection plane)
   loadct, 0
   ;; Sort by distance from observer
   ord = sort(tickz)
   xdat = tickx[ord]
   ydat = ticky[ord]
   zdat = tickz[ord]
   ;; Get rid of locations obscured by Mars or out of bounds
   keep = where( ( zdat lt 0 and $
                   sqrt(xdat^2. + ydat^2.) gt 1 ) and $
                 xdat gt xrange[0] and xdat lt xrange[1] and $
                 ydat gt yrange[0] and ydat lt yrange[1] )
   ;; Display the ticks
   if keepcnt gt 0 then begin
      plots, xdat[keep], ydat[keep], psym=symcat(14), symsize=ss/2.
   endif
   
   
;;; Plot the periapsis below the projection plane
   if keyword_set(showperiapsis) then begin
      vis = periz lt 0 and sqrt( perix^2 + periy^2 ) gt 1
      if vis then $
         plots, perix, periy, psym = symcat(34), symsize=ss*1.5
   endif




;;; Add the overlaid image
   if keyword_set (overlay) then begin
      xdat = reform(mapx,nummaplon*nummaplat)
      ydat = reform(mapy,nummaplon*nummaplat)
      zdat = reform(mapz,nummaplon*nummaplat)
      mapcolor = reform(mapcolor,nummaplon*nummaplat)
      obsview, $
         xdat, ydat, zdat, $
         xout, yout, zout, $
         lon = obslon, lat = obslat
      ord = sort(zout)
      xout = xout[ord]
      yout = yout[ord]
      zout = zout[ord]
      mapcolor = mapcolor[ord]
      
      keepmap = where(zout ge 0 and mapcolor ge 7, keepcnt)
      
      if keepcnt gt 0 then begin
         loadct2, overlay.color_table 
         plots, xout[keepmap], yout[keepmap], color=mapcolor[keepmap], $
                psym=symcat(14), symsize=ss*.8
         loadct, 0
      endif
   endif

; add the crustal field contours
   if keyword_set(crustalfields) then begin
      xdat = contourx
      ydat = contoury
      zdat = contourz
      obsview, $
         xdat, ydat, zdat, $
         xout, yout, zout, $
         lon = obslon, lat = obslat
      ord = sort(zout)
      xout = xout[ord]
      yout = yout[ord]
      zout = zout[ord]
      contourcolor = contourcolor [ord]
      
      keep = where(zout ge 0, keepcnt)
      

      if keepcnt gt 0 then begin
                                ; choose the colors for positive and negative
         loadct, 69
         plots, xout[keep], yout[keep], color=contourcolor[keep], psy=3
         loadct, 0
      endif
   endif
   

;;; Show the latitude lines
   keep = where( zlat ge 0, keepcnt )
   if keepcnt gt 0 then plots, xlat[keep], ylat[keep], psym=3


;;; Show the longitude lines
   keep = where( zlon ge 0, keepcnt )
   if keepcnt gt 0 then plots, xlon[keep], ylon[keep], psym=3


;;; Plot the trajectory above the projection plane
   loadct, orbitcolortable
   cdat = trajcolor
   ;; Sort it by distance from observer
   ord = sort(ztraj)
   xdat = xtraj[ord]
   ydat = ytraj[ord]
   zdat = ztraj[ord]
   cdat = cdat[ord]
   ;; Get rid of locations obscured by Mars or out of bounds
   keep = where( zdat gt 0 and $
                 xdat gt xrange[0] and xdat lt xrange[1] and $
                 ydat gt yrange[0] and ydat lt yrange[1], keepcnt)
   ;; Display the trajectory
   if keepcnt gt 0 then begin
      plots, xdat[keep], ydat[keep], $
             psym=symcat(14), color=cdat[keep], symsize=ss
   endif


;;; Show ticks as black diamonds (above the projection plane)
   loadct, 0
   ;; Sort by distance from observer
   ord = sort(tickz)
   xdat = tickx[ord]
   ydat = ticky[ord]
   zdat = tickz[ord]
   ;; Get rid of locations obscured by Mars or out of bounds
   keep = where( zdat gt 0 and $
                 xdat gt xrange[0] and xdat lt xrange[1] and $
                 ydat gt yrange[0] and ydat lt yrange[1] )
   ;; Display the ticks
   if keepcnt gt 0 then begin
      plots, xdat[keep], ydat[keep], psym=symcat(14), symsize=ss/2.
   endif
   
   
;;; Plot the periapsis above the projection plane
   if keyword_set(showperiapsis) then begin
      vis = periz gt 0
      if vis then $
         plots, perix, periy, psym = symcat(34), symsize=ss*1.5
   endif
   
   
end
