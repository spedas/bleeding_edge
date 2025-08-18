pro plot_mpb, linecolor=linecolor, $
              linethick=linethick, $
        linestyle=linestyle, $
        allangles=allangles, $
              trotignon=trotignon
;;;;;;;;;;
; assumes plot window set, and is in units of Rm
; Dave Brain
; Feb 15 2005
;;;;;;;;;;;;

   IF n_elements(linecolor) EQ 0 THEN linecolor = !p.color
   IF n_elements(linethick) EQ 0 THEN linethick = 1
   IF n_elements(linestyle) EQ 0 THEN linestyle = 0

   angles = findgen(161)*!DTOR
   
   if keyword_set(trotignon) then begin

      ; Draw Trotignon mpb 
         eccen = 0.77                                 ; Eccentricity
         L     = 1.08                                 ; L-distance for mpb
         X0    = 0.64                                 ; Focus
         shockr     = L / ( 1. + eccen *  $           ; find dist to focus
                      cos(angles) )
         shockx     = X0 + shockr *  cos(angles)      ; calculate x
         shockmsd   = shockr * sin(angles)         ; calc dist to Mars-Sun li
         
         eccen = 1.009                                 ; Eccentricity
         L     = 0.528                                 ; L-distance for mpb
         X0    = 1.6                                   ; Focus
         shockr2     = L / ( 1. + eccen *  $           ; find dist to focus
                      cos(angles) )
         shockx2     = X0 + shockr2 *  cos(angles)      ; calculate x
         shockmsd2   = shockr2 * sin(angles)         ; calc dist to Mars-Sun li
         
         nite = where(shockx2 lt 0)
         day = where(shockx gt 0)
         shockx = [ shockx[day], shockx2[nite] ]
         shockmsd = [ shockmsd[day], shockmsd2[nite] ]
         
         oplot, shockx, shockmsd, $   
        thick = linethick, $
        color=linecolor, $
        linestyle=linestyle

      IF n_elements(allangles) NE 0 THEN BEGIN
      
      angles = -1.*findgen(161)*!DTOR
         
      ; Draw Trotignon mpb 
         eccen = 0.77                                 ; Eccentricity
         L     = 1.08                                 ; L-distance for mpb
         X0    = 0.64                                 ; Focus
         shockr     = L / ( 1. + eccen *  $           ; find dist to focus
                      cos(angles) )
         shockx     = X0 + shockr *  cos(angles)      ; calculate x
         shockmsd   = shockr * sin(angles)         ; calc dist to Mars-Sun li
         
         eccen = 1.009                                 ; Eccentricity
         L     = 0.528                                 ; L-distance for mpb
         X0    = 1.6                                   ; Focus
         shockr2     = L / ( 1. + eccen *  $           ; find dist to focus
                      cos(angles) )
         shockx2     = X0 + shockr2 *  cos(angles)      ; calculate x
         shockmsd2   = shockr2 * sin(angles)         ; calc dist to Mars-Sun li
         
         nite = where(shockx2 lt 0)
         day = where(shockx gt 0)
         shockx = [ shockx[day], shockx2[nite] ]
         shockmsd = [ shockmsd[day], shockmsd2[nite] ]
         
         oplot, shockx, shockmsd, $   
        thick = linethick, $
        color=linecolor, $
        linestyle=linestyle
   
      ENDIF

   endif else begin
      
      ; Draw Vignes mpb 
         eccen = 0.90                                 ; Eccentricity
         L     = 0.96                                 ; L-distance for mpb
         X0    = 0.78                                 ; Focus
         shockr     = L / ( 1. + eccen *  $           ; find dist to focus
                      cos(angles) )
         shockx     = X0 + shockr *  cos(angles)      ; calculate x
         shockmsd   = shockr * sin(angles)         ; calc dist to Mars-Sun li
         
         oplot, shockx, shockmsd, $   
        thick = linethick, $
        color=linecolor, $
        linestyle=linestyle
   
      IF n_elements(allangles) NE 0 THEN BEGIN
      
      angles = -1.*findgen(161)*!DTOR
         
      ; Draw Vignes mpb 
         eccen = 0.90                                 ; Eccentricity
         L     = 0.96                                 ; L-distance for mpb
         X0    = 0.78                                 ; Focus
         shockr     = L / ( 1. + eccen *  $           ; find dist to focus
                      cos(angles) )
         shockx     = X0 + shockr *  cos(angles)      ; calculate x
         shockmsd   = shockr * sin(angles)         ; calc dist to Mars-Sun li
         
         oplot, shockx, shockmsd, $   
        thick = linethick, $
        color=linecolor, $
        linestyle=linestyle
   
      ENDIF

   endelse
      
end

pro plot_shock, linecolor=linecolor, $
                linethick=linethick, $
    linestyle=linestyle, $
          allangles=allangles, $
                trotignon=trotignon
;;;;;;;;;;
; assumes plot window set, and is in units of Rm
; Dave Brain
; Feb 15 2005
;;;;;;;;;;;;

   IF n_elements(linecolor) EQ 0 THEN linecolor = !p.color
   IF n_elements(linethick) EQ 0 THEN linethick = 1
   IF n_elements(linestyle) EQ 0 THEN linestyle = 0

   ; Vignes
      epsilon = 1.03
      x0 = .64
      L = 2.04
   ; Trotignon
      if keyword_set(trotignon) then begin
         epsilon = 1.026
         L = 2.081
         x0 = 0.6
      endif

   angles = findgen(161)*!DTOR
      
   ; Draw Vignes mpb 
      shockr     = L / ( 1. + epsilon *  $           ; find dist to focus
                   cos(angles) )
      shockx     = X0 + shockr *  cos(angles)      ; calculate x
      shockmsd   = shockr * sin(angles)         ; calc dist to Mars-Sun li
      
      oplot, shockx, shockmsd, $   
   thick = linethick, $
   color=linecolor, $
   linestyle=linestyle
      
   IF n_elements(allangles) NE 0 THEN BEGIN
   
   angles = -1.*findgen(161)*!DTOR
      
   ; Draw Vignes mpb 
      shockr     = L / ( 1. + epsilon *  $           ; find dist to focus
                   cos(angles) )
      shockx     = X0 + shockr *  cos(angles)      ; calculate x
      shockmsd   = shockr * sin(angles)         ; calc dist to Mars-Sun li
      
      oplot, shockx, shockmsd, $   
   thick = linethick, $
   color=linecolor, $
   linestyle=linestyle

   ENDIF

end


;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mvn_orbql_cylplot_panel.pro
;
; Procedure to create a 2D cylindrical projection plot for a MAVEN spaecraft
; trajectory. 
;
; Syntax:
;      trange = mvn_orbql_cylplot_panel, trange, res
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
;      2. mvn_orbql_colorscale.pro - Dave Brain version of bytscl.pro
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
pro mvn_orbql_cylplot_panel, $
   trange = trange, res = res, $
   xrange = xrange, yrange = yrange, $
   apoapsis=apoapsis, periapsis=periapsis, interest_point=interest_point, ticks=ticks,$
   symsize = ss, charsize = cs, $
   noerase = noerase,$
   orbitcolortable=orbitcolortable
  

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

  if not keyword_set(orbitcolortable) then orbitcolortable = 63
  

;;; Check for ephemeris at proper time resolution
;;;  and load it if it isn't already there and perfect
;;;  Along the way, get the S/C posn in MSO coordinates
  names = tnames()
  mso_present = where(names eq 'mvn_eph_mso')
  if mso_present[0] eq -1 then mvn_barebones_eph, trange, res
  get_data, 'mvn_eph_mso', time, mso
  if time[1] - time[0] ne res or $
     time[0] gt (trange[0] + 60*5) or $
     time[-1] lt (trange[1] - 60*5) then begin
     mvn_barebones_eph, trange, res
     get_data, 'mvn_eph_mso', time, mso
  endif
  mso /= Rm


;;; Set up for the plot
  !p.background = 255
  !p.color = 0


;;; Make the plot axes
  loadct2, 0
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
  
   
;;; Draw Mars and fill it in w/ salmon
  ang = findgen(181) * !dtor
  polyfill, [ cos(ang[90:180]), 0 ], [ sin(ang[90:180]), 0 ], color = 15

  ; ctload, 22, /brewer, /reverse
  loadct2, 62, /reverse
  polyfill, [ cos(ang[0:90]), 0 ], [ sin(ang[0:90]), 0 ], color = 180

  ; ctload, 0
  loadct2, 0
  oplot, cos(ang), sin(ang), thick=2


;;; Draw boundaries
  plot_mpb
  plot_shock


;;; Colorscale data
  color = mvn_orbql_colorscale( time, $
                      mindat=min(trange), maxdat=max(trange), $
                      mincol=20, maxcol=250 )


;;; Plot data
  loadct2, orbitcolortable
  plots, mso[0,*], sqrt(mso[1,*]^2. + mso[2,*]^2.), $
         psym=mvn_orbql_symcat(14), color=color, symsize=ss
   

  loadct2, 0

  ;;; Plot ticks / periapsis / apoapsis / POI, if provided
  strucs = []

  if keyword_set(ticks) then begin
    plots, ticks.x, sqrt(ticks.y^2+ticks.z^2), psym=mvn_orbql_symcat(ticks.m), symsize=ss*ticks.ss
  endif
  if keyword_set(periapsis) then strucs = [strucs, periapsis]
  if keyword_set(apoapsis) then strucs = [strucs, apoapsis]
  if keyword_set(interest_point) then strucs = [strucs, interest_point]

  for i = 0, n_elements(strucs) - 1 do begin
    struc_i = strucs[i]
    plots, struc_i.x, sqrt(struc_i.y^2+struc_i.z^2), psym=mvn_orbql_symcat(struc_i.m), symsize=ss*struc_i.ss
  endfor

;;; Redraw axes
  loadct2, 0
  plot, [0], [0], /nodata, /iso, /noerase, $
        xrange = xrange, xstyle = 1, $
        xtitle = 'MSO X   (R!DM!N)', $
        yrange = yrange, ystyle = 1, $
        ytitle = 'MSO (Y!U2!N + Z!U2!N)!U1/2!N   (R!DM!N)', $
        xthick = 2, ythick = 2, $
        charsize = cs
  
  
;;; Clean up
   !p.background = 255
   !p.color = 0
   
   !p.multi = [0,0,0,0,0]
   !p.region = [0,0,0,0]
   !p.position = [0,0,0,0]
   
   !p.charsize = 1
   !p.charthick = 1
    

end
