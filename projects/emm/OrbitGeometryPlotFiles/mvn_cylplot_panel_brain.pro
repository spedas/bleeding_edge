;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mvn_cylplot_panel_brain.pro
;
; Procedure to create a 2D cylindrical projection plot for a MAVEN spaecraft
; trajectory. 
;
; Syntax:
;      trange = mvn_cylplot_panel_brain, trange, res
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
pro mvn_cylplot_panel_brain, $
   trange = trange, res = res, $
   xrange = xrange, yrange = yrange, $
   showperiapsis = showperiapsis, $
   showticks = showticks, tickinterval = tickinterval, $
   symsize = ss, charsize = cs, $
   noerase = noerase
  

;;; Parameters
  Rm = 3390.

  
;;; Get passed keywords  
  if n_elements(trange) eq 0 then get_timespan, trange
  if n_elements(res) eq 0 then res = 60d0
  if n_elements(xrange) eq 0 then xrange = [-3,3]
  if n_elements(yrange) eq 0 then yrange = [0,3]
  if n_elements(ss) eq 0 then ss = 1
  if n_elements(cs) eq 0 then cs = 1
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


;;; Set up for the plot
  !p.background = 255
  !p.color = 0


;;; Make the plot axes
  loadct, 0
  plot, [0], [0], /nodata, /iso, $
        xrange = xrange, xstyle = 1, $
        xtitle = 'MSO X   (R!DM!N)', $
        yrange = yrange, ystyle = 1, $
        ytitle = 'MSO (Y!U2!N + Z!U2!N)!U1/2!N   (R!DM!N)', $
        xthick = 2, ythick = 2, $
        charsize = cs, noerase = noerase
   

;;; Fill the plot area with gray
  polyfill, color=220, $
            [ xrange, reverse(xrange) ], $
            [ [1,1]*yrange[0], [1,1]*yrange[1] ]
  
   
;;; Draw Mars and fill it in
  ang = findgen(181) * !dtor
  polyfill, [ cos(ang[90:180]), 0 ], [ sin(ang[90:180]), 0 ], color = 0
  loadct2, 70, /reverse
  polyfill, [ cos(ang[0:90]), 0 ], [ sin(ang[0:90]), 0 ], color = 180
  loadct, 0
  oplot, cos(ang), sin(ang), thick=2


;;; Draw boundaries
  plot_mpb
  plot_shock


;;; Colorscale data
  color = colorscale( time, $
                      mindat=min(trange), maxdat=max(trange), $
                      mincol=20, maxcol=250 )


;;; Plot data
  loadct, 63
  plots, mso[0,*], sqrt(mso[1,*]^2. + mso[2,*]^2.), $
         psym=symcat(14), color=color, symsize=ss
   

  
;;; Get periapsis location
  if keyword_set(showperiapsis) then begin
     peritimes = dindgen( trange[1] - trange[0] + 1 ) + trange[0]
     perixdat = spline( time, mso[0,*], peritimes )
     periydat = spline( time, mso[1,*], peritimes )
     perizdat = spline( time, mso[2,*], peritimes )
     perirad = sqrt( perixdat^2 + periydat^2 + perizdat^2 )
     minrad = min(perirad,periind)
     perixdat = perixdat[periind]
     periydat = periydat[periind]
     perizdat = perizdat[periind]
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
     tickxdat = spline( time, mso[0,*], ticktimes )
     tickydat = spline( time, mso[1,*], ticktimes )
     tickzdat = spline( time, mso[2,*], ticktimes )
  endif


;;; Plot tick marks and periapsis location
  loadct, 0
  plots, tickxdat, sqrt(tickydat^2+tickzdat^2), $
         psym=symcat(14), symsize=ss/2.
  plots, perixdat, sqrt(periydat^2+perizdat^2), $
         psym=symcat(34), symsize=ss*1.5


  
;;; Redraw axes
  loadct, 0
  plot, [0], [0], /nodata, /iso, /noerase, $
        xrange = xrange, xstyle = 1, $
        xtitle = 'MSO X   (R!DM!N)', $
        yrange = yrange, ystyle = 1, $
        ytitle = 'MSO (Y!U2!N + Z!U2!N)!U1/2!N   (R!DM!N)', $
        xthick = 2, ythick = 2, $
        charsize = cs
  
  
;;; Clean up
  cleanup
    

end
