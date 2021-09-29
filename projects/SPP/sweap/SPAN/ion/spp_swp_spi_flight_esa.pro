;+
;
; SPP_SWP_SPI_FLIGHT_ESA
;
; Purpose:
;
; SVN Properties
; --------------
; $LastChangedRevision: 26840 $
; $LastChangedDate: 2019-03-17 22:01:08 -0700 (Sun, 17 Mar 2019) $
; $LastChangedBy: rlivi2 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_flight_esa.pro $
;
;-

PRO spp_swp_spi_flight_esa, esa
   
   ;;------------------------------------------------------
   ;; ESA Dimensions
   r1 = 3.34                      ;; Inner Hemisphere Radius
   r2 = r1*1.06                   ;; Outer Hemisphere Radius
   r3 = r1*1.639                  ;; Inner Hemisphere Spherical Radius
   r4 = r3*1.06                   ;; Top Cap Radius
   rd = 3.863                     ;; Deflector Radius
   o1 = [0.000,-2.080]            ;; Origin of Top Cap/Spherical Section
   o2 = [0.480, 0,000]            ;; Origin of Toroidal Section
   o3 = [2.500,-0.575]            ;; Origin of Lower Deflector
   o4 = [2.500, 7.588]            ;; Origin of Upper Deflector

   deg     = findgen(9000.)/100.
   d2      =  2.5                 ;; Distance of def. from rotation axis
   dr      =  3.863               ;; Deflector Radius 38.63mm
   dist    =  0.56                ;; Distance between deflectors (58.7-53.1)
   drp     = dr+dist/2.           ;; Radius of particle path with deflection

   top_def = [[dr*cos(!DTOR*deg)],$       ;x
              [dr*sin(!DTOR*deg)]]        ;y
   top_def_path = [[drp*cos(!DTOR*deg)],$ ;x
                   [drp*sin(!DTOR*deg)]]  ;y
   deg = -1.*deg
   bot_def = [[dr*cos(!DTOR*deg)],$       ;x
              [dr*sin(!DTOR*deg)]]        ;y
   bot_def_path = [[drp*cos(!DTOR*deg)],$ ;x
                   [drp*sin(!DTOR*deg)]]  ;y
   deg = -1.*deg

   esa = {r1:r1,r2:r2,r3:r3,r4:r4,$
          o1:o1,o2:o2,o3:o3,o4:o4} 

   ;; Plotting
   IF keyword_set(plott) THEN BEGIN 
      yaw_vals = fltarr((90-6)*10)
      lin_vals = fltarr((90-6)*10)
      ii=0.
      FOR yaw=  0.,  70.,  5 DO BEGIN
         
         ;; Crude Approximation of Tangent Point
         pp  =  where(ABS(reverse(deg) - yaw) EQ $
                      min(ABS(reverse(deg) - yaw)), cc)
         IF cc EQ 0 THEN stop
         ;; Adjust yaw and linear parameters
         ;; to match tangent line
         theta =  (yaw)*!DTOR
         ;; Top Deflector
         xx =  (top_def[*, 0]+d2)
         yy =  (top_def[*, 1]-dr-dist/2.)
         xx11 =  xx*cos(theta)-yy*sin(theta)
         yy11 =  xx*sin(theta)+yy*cos(theta)
         ;; Top Deflector Path
         xx =  top_def_path[*, 0]+d2
         yy =  top_def_path[*, 1]-dr-dist/2.
         xx22 =  xx*cos(theta)-yy*sin(theta)
         yy22 =  xx*sin(theta)+yy*cos(theta)
         ;; Linear Shift
         lin =  yy22[pp[0]]
         plot,   xx11,  yy11-lin, $
                 xrange=[-10, 10], $
                 yrange=[-10, 10], $
                 ystyle=1, $
                 /iso
         oplot,  xx22,  yy22-lin, $
                 color=250
         ;; Beam
         beam =  [[findgen(1000)-500], [replicate(0., 1000)]]
         oplot,  beam[*, 0],  beam[*, 1]
         ;; Bottom Deflector
         xx =  bot_def[*, 0]+d2
         yy =  bot_def[*, 1]+dr+dist/2.
         xx1 =  xx*cos(theta)-yy*sin(theta)
         yy1 =  xx*sin(theta)+yy*cos(theta)
         oplot,  xx1,  yy1-lin
         xx =  bot_def_path[*, 0]+d2
         yy =  bot_def_path[*, 1]+dr+dist/2.
         xx1 =  xx*cos(theta)-yy*sin(theta)
         yy1 =  xx*sin(theta)+yy*cos(theta)
         oplot,  xx1,  yy1-lin
         ;; Plot temporary location of tangent
         oplot,  top_def_path[pp, 0]+d2,  $
                 top_def_path[pp, 1]-dr-dist/2.,  psym=1
         ;; Information
         xyouts,  -8, -8, $
                  'yaw=' + strtrim(string(yaw),2)+'   '+$
                  'lin=' + strtrim(string(lin),2)
         wait, 0.025   
         yaw_vals[ii] = yaw
         lin_vals[ii] = lin
         ii=ii+1
         IF yaw EQ 65 THEN BREAK ;stop
         IF yaw EQ 70 THEN BREAK ;stop
         
      ENDFOR
   ENDIF
   
      
END

