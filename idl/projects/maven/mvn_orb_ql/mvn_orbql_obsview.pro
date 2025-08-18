pro mvn_orbql_obsview, xin, yin, zin, xout, yout, zout, $
             x0=x0, y0=y0, z0=z0, lon=lon, lat=lat, clock=clock
;;;;;;;;;;;;;;;
; mvn_orbql_obsview.pro
;
; routine to take input cartesian ccordinates and rotate them to
;  a new cartesian system as viewed from the observer's position
;
; lon and lat are assumed to be in radians
; Author: Dave Brain
;;;;;;;


   ; Check keywords and make lon and lat, if necessary
      if n_elements(lon) eq 0 or n_elements(lat) eq 0 then begin
         if n_elements(x0) + n_elements(y0) + n_elements(z0) ne 3 then begin
       lon = 0.
       lat = 0.
         endif else begin
       lon = atan(y0,x0)
       lat = atan( z0, sqrt(x0*x0+y0*y0) )
         endelse
      endif
      if n_elements(clock) eq 0 then clock = 0.
      
   ; First, rotate about z axis through lon degrees
   ; Rotation is clockwise - means observer moves counterclockwise by lon
      xtmp =       xin * cos(lon) + yin * sin(lon)
      ytmp = -1. * xin * sin(lon) + yin * cos(lon)
      ztmp = zin
   
   ; Next rotate about the y axis through lat degrees
   ; Rotation is clockwise - means observer moves up by lat degrees
      xtmp2 =       xtmp * cos(lat) + ztmp * sin(lat)
      ytmp2 = ytmp
      ztmp2 = -1. * xtmp * sin(lat) + ztmp * cos(lat)

   ; Finally, rotate about the x axis through clock degrees
   ; Rotation is clockwise
      xtmp3 = xtmp2
      ytmp3 =       ytmp2 * cos(clock) + ztmp2 * sin(clock)
      ztmp3 = -1. * ytmp2 * sin(clock) + ztmp2 * cos(clock)

   ; Then change to screen coordinates  (y-z physical = x-y screen)
      xout = ytmp3
      yout = ztmp3
      zout = xtmp3

end