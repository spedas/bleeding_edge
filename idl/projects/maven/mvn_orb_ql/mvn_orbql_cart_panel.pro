;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mvn_orbql_cart_panel.pro
;
; Procedure to create a 2D orbit projection plot for a MAVEN spaecraft
; trajectory. 
;
; Syntax:
;      trange = mvn_orbql_cart_panel, trange, res, /xy
;
; Inputs:
;      trange            - 2-elelment timerange over which to plot the
;                          trajectory
;
;      res               - The time resolution to use when plotting
;
;      xy, xz, yz        - Boolean keywords indicating which
;                          projection to plot. No default.
;
;      solidmars         - Boolean: Treat Mars as a solid
;                          object (don't plot trajectory behind
;                          the planet). Default = not set
;
;      msofields     - structure: Color Mars with a map of the
;                          radial component of crustal magnetic field,
;                          as measured by MGS.
;
;      showbehind        - Boolean: Even if Mars is solid, show the
;                          trajectory behind the planet (using
;                          different, smaller symbols). Default = not
;                          set
;
;      [xy]range         - 2-element bounds for the plot, in
;                          Rm. Default = [-3,3]
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
;
; Dave Brain
; 12 January, 2017 -Initial version
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;-
pro mvn_orbql_cart_panel, $
   trange=trange, res=res, $
   xy=xy, xz=xz, yz=yz, $
   solidmars = solidmars,$
   showbehind = showbehind, $
   xrange = xrange, yrange = yrange, $
   symsize = ss, charsize = cs, $
   noerase = noerase, $
   msofields = msofields,$
   periapsis = periapsis, $
   apoapsis=apoapsis,$
   ticks = ticks,$
   interest_point = interest_point,$
   orbitcolortable = orbitcolortable,$
   overlaycolortable = overlaycolortable,$
   reverseoverlaycolortable = reverseoverlaycolortable


  ;;; Parameters
  Rm = 3390.
  
  ;;; Get passed keywords

  ; Time if not set
  if n_elements(trange) eq 0 then get_timespan, trange

  ; resolution of plotted line
  if n_elements(res) eq 0 then res = 60d0

  ; Cartesian projection plot domain
  if n_elements(xrange) eq 0 then xrange = [-3,3]
  if n_elements(yrange) eq 0 then yrange = [-3,3]

  ; Symbol and character size if not set, also default
  ; to erase the prev.
  if n_elements(ss) eq 0 then ss = 1
  if n_elements(cs) eq 0 then cs = 1
  if n_elements(noerase) eq 0 then noerase = 0

  ; Color table parameters
  ; Yellow-to-green for orbit:
  if not keyword_set(orbitcolortable) then orbitcolortable = 63
  ; blue-to-red for crustal fields
  if not keyword_set(overlaycolortable) then overlaycolortable = 70
  if not keyword_set(reverseoverlaycolortable) then reverseoverlaycolortable = 1

  ; If no MSO field parameters passed, only plot Mars solid
  if keyword_set(msofields) eq 0 then solidmars = 1

  ; If provided, get periapsis location
  if keyword_set(periapsis) then begin
    perix = periapsis.x
    periy = periapsis.y
    periz = periapsis.z
  endif

  ; Similarly apoapsis, if provided
  if keyword_set(apoapsis) then begin
    apox = apoapsis.x
    apoy = apoapsis.y
    apoz = apoapsis.z
  endif

  ; and current position (if provided)

  if keyword_set(interest_point) then begin
    interestx = interest_point.x
    interesty = interest_point.y
    interestz = interest_point.z
  endif

  ; Get locations of tick marks
  if keyword_set(ticks) then begin
    tickxdat = ticks.x
    tickydat = ticks.y
    tickzdat = ticks.z
  endif


;;; Check for ephemeris at proper time resolution
;;;  and load it if it isn't already there and perfect
;;;  Along the way, get the S/C posn in MSO coordinates
  names = tnames()
  mso_present = where(names eq 'mvn_eph_mso')

  ; stop

  if mso_present[0] eq -1 then mvn_barebones_eph, trange, res
  get_data, 'mvn_eph_mso', time, mso

  ; print, time[0], time[-1]
  ; print, mso[*, 0], mso[*, -1]

  if time[1] - time[0] ne res or $
     time[0] gt (trange[0] + 60*5) or $
     time[-1] lt (trange[1] - 60*5) then begin
        mvn_barebones_eph, trange, res
        get_data, 'mvn_eph_mso', time, mso
  endif
  mso /= Rm
  ; stop


;;; Get xdata and ydata for latitude lines, in MSO
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
     ; stop
     xlat[*,i] = ans[0,*] / Rm
     ylat[*,i] = ans[1,*] / Rm
     zlat[*,i] = ans[2,*] / Rm
  endfor                        ; i
   
         
;;; Get xdata and ydata for longitude lines, in MSO
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
     ; stop
     xlon[*,i] = ans[0,*] / Rm
     ylon[*,i] = ans[1,*] / Rm
     zlon[*,i] = ans[2,*] / Rm
  endfor                        ; i




  
;;; Make some choices depending upon the projection
  case 1 of
     keyword_set(xy): begin
        xtitle = 'MSO X  (R!DM!N)'
        ytitle = 'MSO Y  (R!DM!N)'

        if keyword_set(msofields) then begin
           cfxdat = msofields.mapx_flat
           cfydat = msofields.mapy_flat
           cfzdat = msofields.mapz_flat
         endif
        latxdat = xlat
        latydat = ylat
        latzdat = zlat
        lonxdat = xlon
        lonydat = ylon
        lonzdat = zlon
        msoxdat = mso[0,*]
        msoydat = mso[1,*]
        msozdat = mso[2,*]
        if keyword_set(periapsis) then begin
           perixplot = perix
           periyplot = periy
           perizplot = periz
        endif

        if keyword_set(apoapsis) then begin
           apoxplot = apox
           apoyplot = apoy
           apozplot = apoz
        endif

        if keyword_set(ticks) then begin
           tickx = tickxdat
           ticky = tickydat
           tickz = tickzdat
        endif

        if keyword_set(interest_point) then begin
           intx = interestx
           inty = interesty
           intz = interestz
        endif

     end
     keyword_set(xz): begin
        xtitle = 'MSO X  (R!DM!N)'
        ytitle = 'MSO Z  (R!DM!N)'

        if keyword_set(msofields) then begin
           cfxdat = msofields.mapx_flat
           cfydat = msofields.mapz_flat
           cfzdat = -1.*msofields.mapy_flat
        endif
        latxdat = xlat
        latydat = zlat
        latzdat = -1.*ylat
        lonxdat = xlon
        lonydat = zlon
        lonzdat = -1.*ylon
        msoxdat = mso[0,*]
        msoydat = mso[2,*]
        msozdat = -1.*mso[1,*]
        if keyword_set(periapsis) then begin
           perixplot = perix
           periyplot = periz
           perizplot = -1.*periy
        endif

        if keyword_set(apoapsis) then begin
           apoxplot = apox
           apoyplot = apoz
           apozplot = -1.*apoy
        endif

        if keyword_set(ticks) then begin
           tickx = tickxdat
           ticky = tickzdat
           tickz = -1.*tickydat
        endif

        if keyword_set(interest_point) then begin
           intx = interestx
           inty = interestz
           intz = -1.*interesty
        endif

     end
     keyword_set(yz): begin
        xtitle = 'MSO Y  (R!DM!N)'
        ytitle = 'MSO Z  (R!DM!N)'
        if keyword_set(msofields) then begin
           cfxdat = msofields.mapy_flat
           cfydat = msofields.mapz_flat
           cfzdat = msofields.mapx_flat
         endif
        latxdat = ylat
        latydat = zlat
        latzdat = xlat
        lonxdat = ylon
        lonydat = zlon
        lonzdat = xlon
        msoxdat = mso[1,*]
        msoydat = mso[2,*]
        msozdat = mso[0,*]
        if keyword_set(periapsis) then begin
           perixplot = periy
           periyplot = periz
           perizplot = perix
        endif

        if keyword_set(apoapsis) then begin
           apoxplot = apoy
           apoyplot = apoz
           apozplot = apox
        endif

        if keyword_set(ticks) then begin
           tickx = tickydat
           ticky = tickzdat
           tickz = tickxdat
        endif

        if keyword_set(interest_point) then begin
           intx = interesty
           inty = interestz
           intz = interestx
        endif

     end     
  endcase
  
  
  
;;; Set up for the plot
   !p.background = 255
   !p.color = 0

;;; Make the plot axes
   loadct2, 0
   plot, [0], [0], /nodata, /iso, $
         xrange = xrange, xstyle = 1, $
         xtitle = xtitle, ytitle = ytitle, $
         yrange = yrange, ystyle = 1, $
         xthick = 2, ythick = 2, $
         charsize = cs, noerase = noerase

   
;;; Fill the plot area with gray
   polyfill, color=220, $
             [ xrange, reverse(xrange) ], $
             [ [1,1]*yrange[0], [1,1]*yrange[1] ]


;;; Add the crustal fields
   if keyword_set(msofields) then begin
      xdat = cfxdat
      ydat = cfydat
      zdat = cfzdat
      color = msofields.mapcolor_flat
      ord = sort(zdat)
      xdat = xdat[ord]
      ydat = ydat[ord]
      zdat = zdat[ord]
      color = color[ord]
      keep = where(zdat ge 0, keepcnt)
      if keepcnt gt 0 then begin
         ; ctload, 22, /brewer, /reverse
         ; loadct2, overlaycolortable, reverse=reverseoverlaycolortable
         initct, overlaycolortable, reverse=reverseoverlaycolortable
         plots, xdat[keep], ydat[keep], color=color[keep], $
                psym=mvn_orbql_symcat(14), symsize=ss*.25
         loadct2, 0
      endif
   endif
      

;;; Draw and shade Mars
   ang = findgen(361) * !dtor
   if keyword_set(xy) or keyword_set(xz) then $
      polyfill, [0,cos(ang[91:271]),0], [0,sin(ang[91:271]),0], $
                color=135, /line_fill, orientation=45, spacing=0.1
   oplot, cos(ang), sin(ang), thick=2
   

;;; Show the latitude lines
   keep = where( latzdat ge 0, keepcnt )
   if keepcnt gt 0 then plots, latxdat[keep], latydat[keep], psym=3


;;; Show the longitude lines
   keep = where( lonzdat ge 0, keepcnt )
   if keepcnt gt 0 then plots, lonxdat[keep], lonydat[keep], psym=3


;;; Colorscale the trajectory
   color = mvn_orbql_colorscale( time, $
                       mindat=min(trange), maxdat=max(trange), $
                       mincol=20, maxcol=250 )

   
;;; Plot the trajectory
   loadct2, orbitcolortable
   cdat = color
   ;; Sort it by distance from observer
   ord = sort(msozdat)
   xdat = msoxdat[ord]
   ydat = msoydat[ord]
   zdat = msozdat[ord]
   cdat = cdat[ord]
   ;; If Mars is solid we either have to get rid
   ;; or some data or display it differently
   keepcnt = 1
   if keyword_set(solidmars) then begin
      keep = where( zdat gt 0 or $
                    sqrt(xdat^2. + ydat^2.) gt 1, keepcnt, $
                    complement = keep2, ncomp = keep2cnt )
      ;; Display the trajectory half size behind Mars if requested
      if keyword_set(showbehind) eq 1 and keep2cnt gt 0 then begin
         x2dat = xdat[keep2]
         y2dat = ydat[keep2]
         z2dat = zdat[keep2]
         c2dat = cdat[keep2]
         plots, x2dat, y2dat, psym=4, color=c2dat, symsize=ss/2.
      endif
      ;; Trim the trajectory to what's visible
      if keepcnt gt 0 then begin
         xdat = xdat[keep]
         ydat = ydat[keep]
         zdat = zdat[keep]
         cdat = cdat[keep]
      endif
   endif
   ;; Display the trajectory
   ; print, xdat[0], ydat[0]

   if keepcnt gt 0 then begin
      plots, xdat, ydat, psym=mvn_orbql_symcat(14), color=cdat, symsize=ss
   endif

   

   if keyword_set(ticks) then begin
      ;;; Show ticks as black diamonds
         loadct2, 0
         ;; Sort by distance from observer
         ord = sort(tickz)
         xdat = tickx[ord]
         ydat = ticky[ord]
         zdat = tickz[ord]
         ;; If Mars is solid we either have to get rid
         ;; or some data or display it differently
         keepcnt = 1
         if keyword_set(solidmars) then begin
            keep = where( zdat gt 0 or $
                          sqrt(xdat^2. + ydat^2.) gt 1, keepcnt, $
                          complement = keep2, ncomp = keep2cnt )
            ;; Display the trajectory half size behind Mars if requested
            if keyword_set(showbehind) eq 1 and keep2cnt gt 0 then begin
               x2dat = xdat[keep2]
               y2dat = ydat[keep2]
               z2dat = zdat[keep2]
               plots, x2dat, y2dat, psym=4, symsize=ss/2.
            endif
            ;; Trim the trajectory to what's visible
            if keepcnt gt 0 then begin
               xdat = xdat[keep]
               ydat = ydat[keep]
               zdat = zdat[keep]
            endif
         endif
         ;; Display the ticks
         if keepcnt gt 0 then begin
            plots, xdat, ydat, psym=mvn_orbql_symcat(14), symsize=ss/2.
         endif
   endif
   
   
;;; Show periapsis as black cross
   if keyword_set(periapsis) then begin
      vis = perizplot gt 0 or sqrt( perixplot^2 + periyplot^2 ) gt 1
      if vis then $
         plots, perixplot, periyplot, psym = mvn_orbql_symcat(periapsis.m), symsize=ss*1.5
      if vis eq 0 and keyword_set(showbehind) eq 1 then $
         plots, perixplot, periyplot, psym = mvn_orbql_symcat(periapsis.m), symsize=ss
   endif


;;; Show apoapsis as filled square
   if keyword_set(apoapsis) then begin
      vis = apozplot gt 0 or sqrt( apoxplot^2 + apoyplot^2 ) gt 1
      if vis then $
         plots, apoxplot, apoyplot, psym = mvn_orbql_symcat(apoapsis.m), symsize=ss*1.5
      if vis eq 0 and keyword_set(showbehind) eq 1 then $
         plots, apoxplot, apoyplot, psym = mvn_orbql_symcat(apoapsis.m), symsize=ss
   endif

;;; Show interest point as black hourglass
   if keyword_set(interest_point) then begin
      vis = intz gt 0 or sqrt( intx^2 + inty^2 ) gt 1
      if vis then $
         plots, intx, inty, psym = mvn_orbql_symcat(interest_point.m), symsize=ss*1.5
      if vis eq 0 and keyword_set(showbehind) eq 1 then $
         plots, intx, inty, psym = mvn_orbql_symcat(interest_point.m), symsize=ss
   endif

   
;;; Redraw the axes
   plot, [0], [0], /nodata, /iso, $
         xrange = xrange, xstyle = 1, $
         xtitle = xtitle, ytitle = ytitle, $
         yrange = yrange, ystyle = 1, $
         xthick = 2, ythick = 2, $
         charsize = cs, /noerase

   !p.background = 255
   !p.color = 0
   
   !p.multi = [0,0,0,0,0]
   !p.region = [0,0,0,0]
   !p.position = [0,0,0,0]
   
   !p.charsize = 1
   !p.charthick = 1
    

end
